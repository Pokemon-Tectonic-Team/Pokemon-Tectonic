module GameData
	class Avatar
		attr_reader :id
		attr_reader :id_number
		attr_reader :num_turns
		attr_reader :form
		attr_reader :moves1
		attr_reader :moves2
		attr_reader :moves3
		attr_reader :post_prime_moves
		attr_reader :ability
		attr_reader :item
		attr_reader :size_mult
		attr_reader :hp_mult
		attr_reader :dmg_mult
		attr_reader :dmg_resist
		attr_reader :num_phases
	
		DATA = {}
		DATA_FILENAME = "avatars.dat"

		SCHEMA = {
		  "Turns"         		=> [:turns,          	"u"],
		  "Form"         		=> [:form,          	"U"],
		  "Moves1"        		=> [:moves1,         	"*e", :Move],
		  "Moves2"      		=> [:moves2,			"*E", :Move],
		  "Moves3"      		=> [:moves3,			"*E", :Move],
		  "Ability"      		=> [:ability,       	"s"],
		  "Item"         		=> [:item,          	"e", :Item],
		  "HPMult"				=> [:hp_mult,			"f"],
		  "SizeMult" 			=> [:size_mult,     	"F"],
		  "DMGMult"				=> [:dmg_mult,			"F"],
		  "DMGResist"			=> [:dmg_resist,		"F"],
		}

		extend ClassMethods
		include InstanceMethods
		
		def initialize(hash)
		  @id               = hash[:id]
		  @id_number        = hash[:id_number]
		  @num_turns        = hash[:turns] || 2
		  @form             = hash[:form] || 0
		  @moves1        	= hash[:moves1]
		  @moves2 			= hash[:moves2] || []
		  @moves3 			= hash[:moves3] || []
		  @ability          = hash[:ability]
		  @item             = hash[:item]
		  @size_mult		= hash[:size_mult] || 1.3
		  @hp_mult			= hash[:hp_mult] || 4.0
		  @dmg_mult 		= hash[:dmg_mult] || 1
		  @dmg_resist		= hash[:dmg_resist] || 0

		  @num_phases = 1
		  if @moves2.length > 0 && @moves2.sort != @moves1.sort
			@num_phases += 1
			if @moves3.length > 0 && @moves3.sort != @moves2.sort
				@num_phases += 1
			end
		  end
		end
	end
end