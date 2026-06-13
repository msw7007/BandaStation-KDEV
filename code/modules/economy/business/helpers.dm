//CYBERPUNK BUSINESS - shared helpers.
/proc/cyberpunk_business_link_list_from_text(raw_text)
	var/list/links = list()
	for(var/link in splittext("[raw_text]", ","))
		var/clean_link = reject_bad_text(trim(link), max_length = 64, ascii_only = FALSE)
		if(clean_link)
			links += clean_link
	return links

/proc/cyberpunk_business_link_list_to_text(list/links)
	if(!islist(links) || !length(links))
		return ""
	return jointext(links, ", ")

/proc/cyberpunk_grant_persistent_access(mob/living/user, datum/cyberpunk_crypto_key/access_key)
	if(!user || !access_key)
		return FALSE
	user.remember_cyberpunk_crypto_key(access_key)
