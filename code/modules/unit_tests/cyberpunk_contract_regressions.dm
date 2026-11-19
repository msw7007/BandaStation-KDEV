/datum/unit_test/cyberpunk_contract_cargo_binding/Run()
	var/mob/living/carbon/human/consistent/contractor = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/cyberpunk_contract/contract = allocate(__IMPLIED_TYPE__)
	contract.id = -1234
	contract.status = CYBERPUNK_CONTRACT_ACCEPTED
	contract.contractor_character_key = contract.user_character_key(contractor)
	contract.creator_confirm_required = TRUE
	var/datum/cyberpunk_contract_condition/delivery/condition = allocate(__IMPLIED_TYPE__)
	condition.destination_kind = "coordinates"
	condition.target_x = contractor.x
	condition.target_y = contractor.y
	condition.target_z = contractor.z
	contract.completion_conditions += condition
	var/obj/item/original = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/obj/item/replacement = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	original.cyberpunk_contract_id = contract.id
	contract.delivery_items += original
	contractor.put_in_active_hand(replacement)
	TEST_ASSERT(!contract.mark_held_item(contractor), "A contractor must not replace reserved cargo.")
	replacement.cyberpunk_contract_id = contract.id
	TEST_ASSERT(!condition.record_item(contract, contractor, replacement), "A forged tag must not authorize another item.")
	TEST_ASSERT(condition.record_item(contract, contractor, original), "The original cargo must remain deliverable.")

/datum/unit_test/cyberpunk_contract_missing_recipient/Run()
	var/mob/living/carbon/human/consistent/creator = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/cyberpunk_contract/contract = allocate(__IMPLIED_TYPE__)
	contract.creator_character_key = contract.user_character_key(creator)
	var/datum/cyberpunk_contract_condition/delivery/condition = allocate(__IMPLIED_TYPE__)
	condition.destination_kind = "recipient"
	condition.destination_text = "nonexistent_contract_recipient_987654321"
	var/obj/item/cargo = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	TEST_ASSERT(!condition.item_at_destination(contract, cargo, creator), "A missing recipient must not fall back to the creator.")
	TEST_ASSERT_NULL(condition.get_ai_destination(contract), "AI delivery must use the same recipient rule.")

/datum/unit_test/cyberpunk_contract_guard_binding/Run()
	var/mob/living/carbon/human/consistent/contractor = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/cyberpunk_contract/contract = allocate(__IMPLIED_TYPE__)
	contract.id = -1235
	contract.contract_type = CYBERPUNK_CONTRACT_GUARD
	contract.status = CYBERPUNK_CONTRACT_ACCEPTED
	contract.contractor_character_key = contract.user_character_key(contractor)
	var/datum/cyberpunk_contract_condition/guard/condition = allocate(__IMPLIED_TYPE__)
	condition.guard_kind = "area"
	contract.completion_conditions += condition
	var/obj/item/replacement = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	contractor.put_in_active_hand(replacement)
	TEST_ASSERT(!contract.mark_held_item(contractor), "Guarding an area must not be replaceable with a held item.")
	TEST_ASSERT_EQUAL(condition.guard_kind, "area", "The original guard kind must be preserved.")
	TEST_ASSERT_NULL(condition.protected_ref, "Marking must not assign a new protected target.")

/datum/unit_test/cyberpunk_contract_penalty_debt/Run()
	var/datum/bank_account/debtor = allocate(__IMPLIED_TYPE__, "Contract debtor", null, 1, FALSE)
	var/datum/bank_account/creditor = allocate(__IMPLIED_TYPE__, "Contract creditor", null, 1, FALSE)
	creditor.account_id = "contract_test_[REF(src)]"
	SSeconomy.bank_accounts_by_id["[creditor.account_id]"] = creditor
	var/datum/cyberpunk_contract/contract = allocate(__IMPLIED_TYPE__)
	contract.penalty = 100
	debtor.account_balance = 25
	contract.charge_penalty(debtor, creditor, "unit test")
	var/paid_immediately = creditor.account_balance
	var/debt_recorded = debtor.account_debt
	debtor.account_balance = 75
	debtor.pay_debt(75)
	var/paid_total = creditor.account_balance
	var/outstanding = contract.penalty_outstanding
	SSeconomy.bank_accounts_by_id -= "[creditor.account_id]"
	TEST_ASSERT_EQUAL(paid_immediately, 25, "Available funds must be paid immediately.")
	TEST_ASSERT_EQUAL(debt_recorded, 75, "The unpaid balance must become bank debt.")
	TEST_ASSERT_EQUAL(paid_total, 100, "Debt collection must pay the contractual creditor.")
	TEST_ASSERT_EQUAL(outstanding, 0, "The claim must be fully settled.")
	TEST_ASSERT_EQUAL(debtor.account_debt, 0, "The bank debt must be fully settled.")
	TEST_ASSERT(!length(debtor.cyberpunk_contract_debts), "Settled claims must be removed.")

/datum/unit_test/cyberpunk_business_vendor_empty_categories/Run()
	var/obj/machinery/vending/tool/cyberpunk_business/vendor = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	TEST_ASSERT(vendor.has_business_vending_module(), "Empty categories must not interrupt business vendor initialization.")
	TEST_ASSERT_EQUAL(length(vendor.product_records), 3, "The test vendor must offer its three standard products.")
	for(var/datum/data/vending_product/product as anything in vendor.product_records)
		TEST_ASSERT_EQUAL(product.amount, 0, "The business vendor starts empty for warehouse testing.")
		TEST_ASSERT_EQUAL(product.max_amount, vendor.products[product.product_path], "An empty business vendor must still have space for warehouse stock.")
	var/obj/item/vending_refill/youtool/refill = allocate(__IMPLIED_TYPE__)
	TEST_ASSERT(vendor.restock(refill) > 0, "An ordinary refill must work when both optional categories are absent.")
