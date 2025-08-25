import argparse
import collections
import configparser
import csv
import io
import logging
import os.path
import re
import select
import socket

from packaging.version import Version

# This is the v19 version of the server. It is not compatible with earlier versions of the script

HOST = r"0.0.0.0"
PORT = 9999
PBS_DIR = r"./PBS"
LOG_DIR = r"."
RULES_DIR = "./OnlinePresets"
# Aprox. in seconds
RULES_REFRESH_RATE = 60

GAME_VERSION = Version("3.3.0")
POKEMON_MAX_NAME_SIZE = 10
PLAYER_MAX_NAME_SIZE = 10
MAXIMUM_LEVEL = 70
IV_STAT_LIMIT = 31
EV_LIMIT = 50
EV_STAT_LIMIT = 20
# Moves that permanently copy other moves
SKETCH_MOVE_IDS = ["SKETCH"]

EBDX_INSTALLED = False


class Server:
    def __init__(self, host, port, pbs_dir, rules_dir):
        self.valid_party = make_party_validator(pbs_dir)
        self.loop_count = 1
        _, self.rules_files = find_changed_files(rules_dir, {})
        self.rules = load_rules_files(rules_dir, self.rules_files)
        self.host = host
        self.port = port
        self.rules_dir = rules_dir
        self.socket = None
        self.clients = {}
        self.handlers = {
            Connecting: self.handle_connecting,
            Finding: self.handle_finding,
            Connected: self.handle_connected,
        }

    def run(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as self.socket:
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socket.bind((self.host, self.port))
            logging.info("Started Server on %s:%d", self.host, self.port)
            self.socket.listen()
            while True:
                try:
                    self.loop()
                except KeyboardInterrupt:
                    logging.info("Stopping Server")
                    break

    def loop(self):
        if (self.loop_count % RULES_REFRESH_RATE) == 0:
            reload_rules, rule_files = find_changed_files(
                self.rules_dir, self.rules_files
            )
            if reload_rules:
                self.rules_files = rule_files
                self.rules = load_rules_files(self.rules_dir, self.rules_files)
            self.loop_count = 0
        self.loop_count += 1
        reads = list(self.clients)
        reads.append(self.socket)
        writes = [s for s, st in self.clients.items() if st.send_buffer]
        readable, writeable, errors = select.select(reads, writes, reads, 1.0)
        for s in errors:
            if s is self.socket:
                raise Exception("error on listening socket")
            else:
                self.disconnect(s)

        for s in writeable:
            st = self.clients[s]
            try:
                n = s.send(st.send_buffer)
            except Exception as e:
                self.disconnect(s, e)
            else:
                st.send_buffer = st.send_buffer[n:]

        for s in readable:
            if s is self.socket:
                s, address = self.socket.accept()
                s.setblocking(False)
                st = self.clients[s] = State(address)
                logging.info("%s: connect", st)
            else:
                st = self.clients[s]
                try:
                    recvd = s.recv(4096)
                except ConnectionResetError as e:
                    self.disconnect(s)
                else:
                    if recvd:
                        recv_buffer = st.recv_buffer + recvd
                        while True:
                            message, _, recv_buffer = recv_buffer.partition(b"\n")
                            if not _:
                                # No newline, buffer the partial message.
                                st.recv_buffer = message
                                break
                            else:
                                try:
                                    # Handle the message.
                                    self.handlers[type(st.state)](s, st, message)
                                except Exception as e:
                                    logging.exception("Server Error", exc_info=e)
                                    self.disconnect(s, "server error")
                    else:
                        # Zero-length read from a non-blocking socket is
                        # a disconnect.
                        self.disconnect(s, "client disconnected")

    def connect(self, s, s_):
        connections = [(0, s_, s), (1, s, s_)]
        for number, s, s_ in connections:
            st = self.clients[s]
            st_ = self.clients[s_]
            writer = RecordWriter()
            writer.str("found")
            writer.int(number)
            writer.str(st_.state.name)
            writer.str(st_.state.trainertype)
            writer.int(st_.state.win_text)
            writer.int(st_.state.lose_text)
            writer.raw(st_.state.party)
            self.write_server_rules(writer)
            writer.send(st)

        for _, s, s_ in connections:
            st = self.clients[s]
            st.state = Connected(s_)

        for _, s, s_ in connections:
            st = self.clients[s]
            st_ = self.clients[s_]
            logging.info("%s: connected to %s", st, st_)

    def disconnect(self, s, reason="unknown error"):
        try:
            st = self.clients.pop(s)
        except:
            pass
        else:
            try:
                writer = RecordWriter()
                writer.str("disconnect")
                writer.str(reason)
                writer.send_now(s)
                s.close()
            except Exception:
                pass
            logging.info("%s: disconnected (%s)", st, reason)
            if isinstance(st.state, Connected):
                self.disconnect(st.state.peer, "peer disconnected")

    # Connecting, validate the party, and connect to peer if possible.
    def handle_connecting(self, s, st, message):
        record = RecordParser(message.decode("utf8"))
        if record.str() != "find":
            self.disconnect(s, "bad assert")
        else:
            version = record.str()
            if not Version(version) >= GAME_VERSION:
                self.disconnect(s, "invalid version")
            else:
                peer_id = record.int()
                name = record.str()
                id = record.int()
                ttype = record.str()
                win_text = record.int()
                lose_text = record.int()
                party = record.raw_all()
                logging.debug(
                    "%s: Trainer %s, id %d (%s) -> Searching %d",
                    st,
                    name,
                    public_id(id),
                    hex(id),
                    peer_id,
                )
                if not self.valid_party(record):
                    self.disconnect(s, "invalid party")
                else:
                    st.state = Finding(
                        peer_id, name, id, ttype, party, win_text, lose_text
                    )
                    # Is the peer already waiting?
                    for s_, st_ in self.clients.items():
                        if (
                            st is not st_
                            and isinstance(st_.state, Finding)
                            and public_id(st_.state.id) == peer_id
                            and st_.state.peer_id == public_id(id)
                        ):
                            self.connect(s, s_)

    # Finding, simply ignore messages until the peer connects.
    def handle_finding(self, s, st, message):
        logging.info("%s: message dropped (no peer)", st)

    # Connected, simply forward messages to the peer.
    def handle_connected(self, s, st, message):
        st_ = self.clients.get(st.state.peer)
        if st_:
            st_.send_buffer += message + b"\n"
        else:
            logging.info("%s: message dropped (no peer)", st)

    def write_server_rules(self, writer):
        writer.int(len(self.rules))
        for r in self.rules:
            writer.raw(r)


class State:
    def __init__(self, address):
        self.address = address
        self.state = Connecting()
        self.send_buffer = b""
        self.recv_buffer = b""

    def __str__(self):
        return (
            f"{self.address[0]}:{self.address[1]}/{type(self.state).__name__.lower()}"
        )


Connecting = collections.namedtuple("Connecting", "")
Finding = collections.namedtuple(
    "Finding", "peer_id name id trainertype party win_text lose_text"
)
Connected = collections.namedtuple("Connected", "peer")


class RecordParser:
    def __init__(self, line):
        self.fields = []
        field = ""
        escape = False
        for c in line:
            if c == "," and not escape:
                self.fields.append(field)
                field = ""
            elif c == "\\" and not escape:
                escape = True
            else:
                field += c
                escape = False
        self.fields.append(field)
        self.fields.reverse()

    def bool(self):
        return {"true": True, "false": False}[self.fields.pop()]

    def bool_or_none(self):
        return {"true": True, "false": False, "": None}[self.fields.pop()]

    def int(self):
        return int(self.fields.pop())

    def int_or_none(self):
        field = self.fields.pop()
        if not field:
            return None
        else:
            return int(field)

    def str(self):
        return self.fields.pop()

    def raw_all(self):
        return list(reversed(self.fields))


def public_id(id_):
    return id_ & 0xFFFF


class RecordWriter:
    def __init__(self):
        self.fields = []

    def send_now(self, s):
        line = ",".join(RecordWriter.escape(f) for f in self.fields)
        line += "\n"
        s.send(line.encode("utf8"))

    def send(self, st):
        line = ",".join(RecordWriter.escape(f) for f in self.fields)
        line += "\n"
        st.send_buffer += line.encode("utf8")

    @staticmethod
    def escape(f):
        return f.replace("\\", "\\\\").replace(",", "\\,")

    def int(self, i):
        self.fields.append(str(i))

    def str(self, s):
        self.fields.append(s)

    def raw(self, fs):
        self.fields.extend(fs)


Pokemon = collections.namedtuple("Pokemon", "genders abilities moves forms")


class Universe:
    def __contains__(self, item):
        return True


def make_party_validator(pbs_dir):
    ability_syms = set()
    move_syms = set()
    item_syms = set()
    pokemon_by_name = {}

    with io.open(
        os.path.join(pbs_dir, r"abilities.txt"), "r", encoding="utf-8-sig"
    ) as abilities_pbs:
        abilities_pbs_ = configparser.ConfigParser()
        abilities_pbs_.read_file(abilities_pbs)
        for internal_id in abilities_pbs_.sections():
            ability_syms.add(internal_id)

    with io.open(
        os.path.join(pbs_dir, r"abilities_new.txt"), "r", encoding="utf-8-sig"
    ) as abilities_pbs:
        abilities_pbs_ = configparser.ConfigParser()
        abilities_pbs_.read_file(abilities_pbs)
        for internal_id in abilities_pbs_.sections():
            ability_syms.add(internal_id)

    with io.open(
        os.path.join(pbs_dir, r"moves.txt"), "r", encoding="utf-8-sig"
    ) as moves_pbs:
        moves_pbs_ = configparser.ConfigParser()
        moves_pbs_.read_file(moves_pbs)
        for internal_id in moves_pbs_.sections():
            move_syms.add(internal_id)

    with io.open(
        os.path.join(pbs_dir, r"moves_new.txt"), "r", encoding="utf-8-sig"
    ) as moves_pbs:
        moves_pbs_ = configparser.ConfigParser()
        moves_pbs_.read_file(moves_pbs)
        for internal_id in moves_pbs_.sections():
            move_syms.add(internal_id)

    with io.open(
        os.path.join(pbs_dir, r"items.txt"), "r", encoding="utf-8-sig"
    ) as items_pbs:
        items_pbs_ = configparser.ConfigParser()
        items_pbs_.read_file(items_pbs)
        for internal_id in items_pbs_.sections():
            item_syms.add(internal_id)

    with io.open(
        os.path.join(pbs_dir, r"pokemon_server.txt"), "r", encoding="utf-8-sig"
    ) as pokemon_pbs:
        pokemon_pbs_ = configparser.ConfigParser()
        pokemon_pbs_.read_file(pokemon_pbs)
        for section in pokemon_pbs_.sections():
            species = pokemon_pbs_[section]
            if "forms" in species:
                forms = {int(f) for f in species["forms"].split(",") if f}
            else:
                forms = Universe()
            genders = {
                "AlwaysMale": {0},
                "AlwaysFemale": {1},
                "Genderless": {2},
            }.get(species["gender_ratio"], {0, 1})
            ability_names = species["abilities"].split(",")
            abilities = {a for a in ability_names if a}
            moves = {m for m in species["moves"].split(",") if m}
            pokemon_by_name[section] = Pokemon(genders, abilities, moves, forms)

    def validate_party(record):
        logging.debug("--BEGIN PARTY VALIDATION--")
        errors = []
        try:
            for _ in range(record.int()):

                def validate_pokemon():
                    species = record.str()
                    species_ = pokemon_by_name.get(species)
                    if species_ is None:
                        logging.debug("invalid species: %s", species)
                        errors.append("invalid species")
                    logging.debug("Species: %s", species)
                    level = record.int()
                    if not (1 <= level <= MAXIMUM_LEVEL):
                        logging.debug("invalid level: %d", level)
                        errors.append("invalid level")
                    personal_id = record.int()
                    owner_id = record.int()
                    if owner_id & ~0xFFFFFFFF:
                        logging.debug("invalid owner id: %d", owner_id)
                        errors.append("invalid owner id")
                    owner_name = record.str()
                    if not (len(owner_name) <= PLAYER_MAX_NAME_SIZE):
                        logging.debug("invalid owner name: %s", owner_name)
                        errors.append("invalid owner name")
                    owner_gender = record.int()
                    if owner_gender not in {0, 1, 2}:
                        logging.debug("invalid owner gender: %d", owner_gender)
                        errors.append("invalid owner gender")
                    exp = record.int()
                    # TODO: validate exp.
                    form = record.int()
                    if form not in species_.forms:
                        logging.debug("invalid form: %d", form)
                        errors.append("invalid form")
                    item1 = record.str()
                    if item1 and item1 not in item_syms:
                        logging.debug("invalid item id: %s", item1)
                        errors.append("invalid item")
                    item2 = record.str()
                    if item2 and item2 not in item_syms:
                        logging.debug("invalid item id: %s", item2)
                        errors.append("invalid item")
                    can_use_sketch = not set(SKETCH_MOVE_IDS).isdisjoint(species_.moves)
                    for _ in range(record.int()):
                        move = record.str()
                        if move:
                            if can_use_sketch and move not in move_syms:
                                logging.debug("invalid move id (Sketched): %s", move)
                                errors.append("invalid move (Sketched)")
                            elif move not in species_.moves and not can_use_sketch:
                                logging.debug("invalid move id: %s", move)
                                errors.append("invalid move")
                        ppup = record.int()
                        if not (0 <= ppup <= 3):
                            logging.debug("invalid ppup for move id %s: %d", move, ppup)
                            errors.append("invalid ppup")
                    for _ in range(record.int()):
                        move = record.str()
                        if move:
                            if can_use_sketch and move not in move_syms:
                                logging.debug(
                                    "invalid first move id (Sketched): %s", move
                                )
                                errors.append("invalid first move (Sketched)")
                            elif move not in species_.moves and not can_use_sketch:
                                logging.debug("invalid first move id: %s", move)
                                errors.append("invalid first move")
                    gender = record.int()
                    if gender not in species_.genders:
                        logging.debug("invalid gender: %d", gender)
                        errors.append("invalid gender")
                    shiny = record.bool_or_none()
                    ability = record.str()
                    # stricter check
                    if ability and ability not in species_.abilities:
                        logging.debug("invalid ability strict: %s", ability)
                        errors.append("invalid ability strict")
                    if ability and ability not in ability_syms:
                        logging.debug("invalid ability: %s", ability)
                        errors.append("invalid ability")
                    ability_index = (
                        record.int_or_none()
                    )  # so hidden abils are properly inherited
                    nature_id = record.str()
                    nature_stats_id = record.str()
                    ev_sum = 0
                    attack_ev = 0
                    for i in range(6):
                        ev = record.int()
                        if i == 1:
                            attack_ev = ev
                        if not (0 <= ev <= EV_STAT_LIMIT):
                            logging.debug("invalid EV: %d", ev)
                            errors.append("invalid EV")
                        ev_sum += ev
                    ev_sum -= attack_ev  # dedupe atk + spatk ev
                    if not (0 <= ev_sum <= EV_LIMIT):
                        logging.debug("invalid EV sum: %d", ev_sum)
                        errors.append("invalid EV sum")
                    happiness = record.int()
                    if not (0 <= happiness <= 255):
                        logging.debug("invalid happiness: %d", happiness)
                        errors.append("invalid happiness")
                    name = record.str()
                    # if not (len(name) <= POKEMON_MAX_NAME_SIZE):
                    #     logging.debug("invalid name: %s", name)
                    #     errors.append("invalid name")
                    poke_ball = record.str()
                    if poke_ball and poke_ball not in item_syms:
                        logging.debug("invalid pokeball: %s", poke_ball)
                        errors.append("invalid pokeball")
                    steps_to_hatch = record.int()
                    # obtain data
                    obtain_mode = record.int()
                    obtain_map = record.int()
                    obtain_text = record.str()
                    obtain_level = record.int()
                    hatched_map = record.int()
                    # contest stats
                    cool = record.int()
                    beauty = record.int()
                    cute = record.int()
                    smart = record.int()
                    tough = record.int()
                    sheen = record.int()
                    # ribbons
                    for _ in range(record.int()):
                        ribbon = record.str()
                        m_item = record.str()
                        m_msg = record.str()
                        m_sender = record.str()
                        m_species1 = record.int_or_none()
                        if m_species1:
                            # [species,gender,shininess,form,shadowness,is egg]
                            m_gender1 = record.int()
                            m_shiny1 = record.bool()
                            m_form1 = record.int()
                            m_shadow1 = record.bool()
                            m_egg1 = record.bool()

                        m_species2 = record.int_or_none()
                        if m_species2:
                            # [species,gender,shininess,form,shadowness,is egg]
                            m_gender2 = record.int()
                            m_shiny2 = record.bool()
                            m_form2 = record.int()
                            m_shadow2 = record.bool()
                            m_egg2 = record.bool()

                        m_species3 = record.int_or_none()
                        if m_species3:
                            # [species,gender,shininess,form,shadowness,is egg]
                            m_gender3 = record.int()
                            m_shiny3 = record.bool()
                            m_form3 = record.int()
                            m_shadow3 = record.bool()
                            m_egg3 = record.bool()
                    # fused
                    if record.bool():
                        logging.debug("Fused Mon")
                        validate_pokemon()
                    if EBDX_INSTALLED:
                        superhue = record.str()
                        if shiny and (superhue == ""):
                            logging.debug("uninitialized supershiny")
                            errors.append("uninitialized supershiny")
                        supervarient = record.bool_or_none()
                    logging.debug("-------")

                validate_pokemon()
            rest = record.raw_all()
            if rest:
                errors.append(f"remaining data: {', '.join(rest)}")
        except Exception as e:
            errors.append(str(e))
        if errors:
            logging.debug("Errors: %s", errors)
        logging.debug("--END PARTY VALIDATION--")
        return not errors

    return validate_party


def find_changed_files(directory, old_files_hash):
    if os.path.isdir(directory):
        new_files_hash = dict(
            [
                (f, os.stat(os.path.join(directory, f)).st_mtime)
                for f in os.listdir(directory)
            ]
        )
        changed = old_files_hash.keys() != new_files_hash.keys()
        if not changed:
            for k in old_files_hash.keys() & new_files_hash.keys():
                if old_files_hash[k] != new_files_hash[k]:
                    changed = True
                    break
        if changed:
            logging.info("Refreshing Rules due to changes")
            return True, new_files_hash
    return False, old_files_hash


def load_rules_files(directory, files_hash):
    rules = []
    for f in iter(files_hash):
        rule = []
        with open(os.path.join(directory, f)) as rule_file:
            for num, line in enumerate(rule_file):
                line = line.strip()
                if num == 3:
                    rule.extend(line.split(","))
                else:
                    rule.append(line)
        rules.append(rule)
    return rules


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--host",
        default=HOST,
        help="The host IP Address to run this server on. Should be 0.0.0.0 for Google Cloud.",
    )
    parser.add_argument(
        "--port", default=PORT, help="The port the server is listening on."
    )
    parser.add_argument(
        "--pbs_dir",
        default=PBS_DIR,
        help="The path, relative to the working directory, where the PBS files are located.",
    )
    parser.add_argument(
        "--rules_dir",
        default=RULES_DIR,
        help="The path, relative to the working directory, where the rules files are located.",
    )
    parser.add_argument(
        "--log",
        default="INFO",
        help="The log level of the server. Logging messages lower than the level are not written.",
    )
    args = parser.parse_args()
    loglevel = getattr(logging, args.log.upper())
    if not isinstance(loglevel, int):
        raise ValueError("Invalid log level: %s" % loglevel)
    logging.basicConfig(
        format="%(asctime)s: %(levelname)s: %(message)s",
        filename=os.path.join(LOG_DIR, "server.log"),
        level=loglevel,
    )
    logging.info("---------------")
    Server(args.host, int(args.port), args.pbs_dir, args.rules_dir).run()
    logging.shutdown()
