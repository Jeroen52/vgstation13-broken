//device to take core samples from mineral turfs - used for various types of analysis

/obj/item/weapon/storage/box/samplebags
	name = "sample bag box"
	desc = "A box claiming to contain sample bags."

/obj/item/weapon/storage/box/samplebags/New()
	for(var/i=0, i<7, i++)
		var/obj/item/weapon/evidencebag/S = new(src)
		S.name = "sample bag"
		S.desc = "a bag for holding research samples."
	..()
	return

//////////////////////////////////////////////////////////////////

/obj/item/device/core_sampler
	name = "core sampler"
	desc = "Used to extract geological core samples."
	icon = 'icons/obj/device.dmi'
	icon_state = "sampler0"
	item_state = "screwdriver_brown"
	w_class = W_CLASS_TINY
	flags = FPRINT
	//slot_flags = SLOT_BELT
	var/sampled_turf = ""
	var/num_stored_bags = 10
	var/obj/item/weapon/evidencebag/filled_bag

/obj/item/device/core_sampler/examine(mob/user)
	..()
	if(get_dist(src, user) < 2)
		to_chat(user, "<span class='info'>This one is [sampled_turf ? "full" : "empty"], and has [num_stored_bags] bag[num_stored_bags != 1 ? "s" : ""] remaining.</span>")

/obj/item/device/core_sampler/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/weapon/evidencebag))
		if(num_stored_bags < 10)
			to_chat(user, "<span class='notice'>You insert the [W] into the core sampler.</span>")
			qdel(W)
			W = null
			num_stored_bags += 1
			return 1
		else
			to_chat(user, "<span class='warning'>The core sampler can not fit any more bags!</span>")
	else
		return ..()

/obj/item/device/core_sampler/proc/sample_item(var/item_to_sample, var/mob/user as mob)
	var/datum/geosample/geo_data
	if(istype(item_to_sample, /turf/unsimulated/mineral))
		var/turf/unsimulated/mineral/T = item_to_sample
		T.geologic_data.UpdateNearbyArtifactInfo(T)
		geo_data = T.geologic_data
	else if(istype(item_to_sample, /obj/item/weapon/strangerock))
		var/obj/item/weapon/strangerock/O = item_to_sample
		geo_data = O.geologic_data

	if(geo_data)
		if(filled_bag)
			to_chat(user, "<span class='warning'>The core sampler is full!</span>")
		else if(num_stored_bags < 1)
			to_chat(user, "<span class='warning'>The core sampler is out of sample bags!</span>")
		else
			//create a new sample bag which we'll fill with rock samples
			filled_bag = new /obj/item/weapon/evidencebag(src)
			filled_bag.name = "sample bag"
			filled_bag.desc = "a bag for holding research samples."

			icon_state = "sampler1"
			num_stored_bags--

			//put in a rock sliver
			var/obj/item/weapon/rocksliver/R = new()
			R.geological_data = geo_data
			R.forceMove(filled_bag)

			//update the sample bag
			filled_bag.icon_state = "evidence"
			var/image/I = image("icon"=R, "layer"=FLOAT_LAYER)
			I.plane = FLOAT_PLANE
			filled_bag.underlays += I
			filled_bag.w_class = W_CLASS_TINY

			to_chat(user, "<span class='notice'>You take a core sample of the [item_to_sample].</span>")
	else
		to_chat(user, "<span class='warning'>You are unable to take a sample of [item_to_sample].</span>")

/obj/item/device/core_sampler/attack_self()
	if(filled_bag)
		to_chat(usr, "<span class='notice'>You eject the full sample bag.</span>")
		var/success = 0
		if(istype(src.loc, /mob))
			var/mob/M = src.loc
			success = M.put_in_inactive_hand(filled_bag)
		if(!success)
			filled_bag.forceMove(get_turf(src))
		filled_bag = null
		icon_state = "sampler0"
	else
		to_chat(usr, "<span class='warning'>The core sampler is empty.</span>")
