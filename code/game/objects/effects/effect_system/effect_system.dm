/* This is an attempt to make some easily reusable "particle" type effect, to stop the code
constantly having to be rewritten. An item like the jetpack that uses the ion_trail_follow system, just has one
defined, then set up when it is created with New(). Then this same system can just be reused each time
it needs to create more trails.A beaker could have a steam_trail_follow system set up, then the steam
would spawn and follow the beaker, even if it is carried or thrown.
*/


/obj/effect/particle_effect
	name = "particle effect"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pass_flags = PASSTABLE | PASSGRILLE
	anchored = TRUE

/obj/effect/particle_effect/Initialize()
	. = ..()
	GLOB.cameranet.updateVisibility(src)

/obj/effect/particle_effect/Destroy()
	GLOB.cameranet.updateVisibility(src)
	return ..()

/obj/effect/particle_effect/newtonian_move() // Prevents effects from getting registered for SSspacedrift
	return TRUE

/datum/effect_system
	var/number = 3
	var/cardinals = FALSE
	var/turf/location
	var/atom/holder
	var/obj/particle_holder/PMover // for particles
	var/effect_type
	var/particle_type
	var/total_effects = 0
	var/autocleanup = FALSE //will delete itself after use

/datum/effect_system/Destroy()
	holder = null
	location = null
	return ..()

/datum/effect_system/proc/set_up(n = 3, c = FALSE, loca)
	if(n > 10)
		n = 10
	number = n
	cardinals = c
	if(isturf(loca))
		location = loca
	else
		location = get_turf(loca)

/obj/particle_holder
	name = "Particle Holder"

/obj/particle_holder/sparks
	particles = new/particles/sparks
	anchored = TRUE
	light_system = MOVABLE_LIGHT
	light_range = 2
	light_power = 0.5
	light_color = LIGHT_COLOR_FIRE

/obj/particle_holder/sparks/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD
	
/obj/particle_holder/sparks/LateInitialize()
	flick(icon_state, src)
	playsound(src, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	var/turf/T = loc
	if(isturf(T))
		T.hotspot_expose(1000,100)
	QDEL_IN(src, 20)

/obj/particle_holder/sparks/Destroy()
	var/turf/T = loc
	if(isturf(T))
		T.hotspot_expose(1000,100)
	return ..()

/obj/particle_holder/sparks/Move(atom/newloc, direct, glide_size_override)
	. = ..()
	var/turf/T = loc
	if(isturf(T))
		T.hotspot_expose(1000,100)

particles/sparks
	width = 1
	height = 1
	color = "yellow"
	count = 60
	spawning = 20
	lifespan = 20
	bound1 = list(-64, -64)
	bound2 = list(64, 64)
	position = generator("box", list(-32, -32, 0), list(0, 0, 1))
	drift = generator("sphere", 0, 2)

/datum/effect_system/proc/attach(atom/atom)
	holder = atom

/datum/effect_system/proc/start()
	if(QDELETED(src))
		return
	if(particle_type)
		INVOKE_ASYNC(src, .proc/generate_particle)
		return
	for(var/i in 1 to number)
		if(total_effects > 20)
			return
		INVOKE_ASYNC(src, .proc/generate_effect)

/datum/effect_system/proc/generate_particle()
	if(holder)
		location = get_turf(holder)
	var/obj/particle_holder/P = new particle_type(location)
	PMover = P
	var/direct
	if(cardinals)
		direct = pick(GLOB.cardinals)
	else
		direct = pick(GLOB.alldirs)
/* 	var/x
	var/y
	if(direct & NORTH)
		y = 1
	if(direct & SOUTH)
		y = -1
	if(direct & EAST)
		x = 1
	if(direct & WEST)
		x = -1 */
	var/steps_amt = pick(1, 2, 3)
	for(var/j in 1 to steps_amt)
		addtimer(CALLBACK(src, .proc/delayed_particle_step, direct), 5)

/datum/effect_system/proc/delayed_particle_step(var/direction)
	step(PMover, direction)


/datum/effect_system/proc/generate_effect()
	if(holder)
		location = get_turf(holder)
	var/obj/effect/E = new effect_type(location)
	total_effects++
	var/direction
	if(cardinals)
		direction = pick(GLOB.cardinals)
	else
		direction = pick(GLOB.alldirs)
	var/steps_amt = pick(1,2,3)
	for(var/j in 1 to steps_amt)
		sleep(5)
		step(E,direction)
	if(!QDELETED(src))
		addtimer(CALLBACK(src, .proc/decrement_total_effect), 20)

/datum/effect_system/proc/decrement_total_effect()
	total_effects--
	if(autocleanup && total_effects <= 0)
		qdel(src)
