ItemHandlers::UseFromBag.add(:SMARTPHONE,proc { |item|
	next 2
})

ItemHandlers::ConfirmUseInField.add(:SMARTPHONE,proc { |item|
  next true
})

ItemHandlers::UseInField.add(:SMARTPHONE,proc { |item|
	next takeSelfie
})