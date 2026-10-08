// Event statistic: count and running maximum, both capped at 9999.
typedef struct StatPair {
    short count;
    short max;
} StatPair;

// Fighter logical-input history sample; 32 per fighter.
typedef struct InputSample {
    unsigned int logical; // logical input mask
    float magnitude; // left-stick magnitude / 255
    float angle; // left-stick angle
} InputSample;

// Action-descriptor phase record; a condition of -1 ends the list.
typedef struct PhaseRecord {
    short animation_slot; // index into Fighter.animations
    short condition; // -0x10 anim end, -0x11 grounded, -0x12 falling or grounded, -0x13 end or grounded, -0x14 end and grounded, 0 held, >0 secondary cursor
    short start_frame;
    short rate; // animation and secondary-timeline rate /256; copied to Fighter.secondary_rate
} PhaseRecord;

// Action-descriptor table row, indexed by substate.
typedef struct ActionDescriptor {
    char *identifier; // native ACT_ identifier
    PhaseRecord *phases;
} ActionDescriptor;

typedef struct ActionRecord {
    char *debug_name; // always the empty string in retail data
    unsigned char _pad_0004[0x4];
    char *display_name; // Shift-JIS move name
    unsigned short owner_character;
    short jutsu_selector;
    unsigned int category; // 0x2 fixed slot 19 and forced lock, 0xF000 chain group, 0xF0000 hold/companion, 0xF00000 jutsu
    unsigned int flags; // 0x380 mode-1 group, 0x1C00 exchange group, 0x20000 no attacker pause, 0x80000/0x100000 contact rebound, 0x200000 rehit bypass, 0x400000/0x800000 guard bypass
    signed char continuation; // -1 immediate, -2 chain/any, else required current action index
    union { unsigned char streak_exempt; signed char display_prefix; }; // zero lets a long receiver streak force response 0x37; AI reads this as signed category and the queue uses it as category 0..3
    union { signed char ai_reaction_scalar; signed char substitution_timing; }; // +0x1A; AI -3..3 maps to -0.5,-0.3,-0.1,0,0.1,0.3,0.5; substitution independently uses signed history distance/modulo gate
    unsigned char _pad_001B[1];
    unsigned int signature; // normalized input signature
    float cost; // chakra cost
    float damage; // authored stage-hit damage scalar; divided by repeat_count by common consumer
    float knockback_scale; // copied to Fighter.attack_scale
    unsigned char response_selector; // ordinary-response selector; 0xFF on non-damaging records
    signed char guard_selector; // guarded-response row 0..9
    short repeat_count; // expected hit count; copied to Fighter.attack_repeat_countdown
    short update_pause; // positive staged, negative immediate, 0x7FFF use the response row
    short rejection_count; // positive staged, negative immediate, 0x7FFF use the response row
    float threshold; // contextual threshold; -17320.508 resolved at setup
    float threshold_2; // second threshold; same sentinel
    float capture_facing_distance_factor; // +0x3C scaled-width distance test; sign reverses capture receiver facing
    short audio_sfx;
    short audio_voice;
    short audio_time;
    short response_sfx;
    unsigned char _pad_0048[2];
    short guard_sfx;
    unsigned char _pad_004C[2];
    short response_voice;
    union { int row; ExchangeAttackMotionView *exchange_motion; }; // +0x50 authored row index becomes a 0x4C-byte row pointer at setup; exchange retarget copies slot and six motion fields
} ActionRecord;

// Ordinary-response motion row, indexed by substate - 0x27.
typedef struct ResponseMotionRow {
    unsigned short flags; // 0x0101 replace both speeds, 0x0201 add them; low bits pick the primary timeline
    short event_gate; // primary-timeline event that applies the motion
    float planar_speed;
    float vertical_speed;
    float damping; // planar approach factor on other updates
    float gravity_aux; // copied to Fighter.next_gravity; only lifts the -90 clamp
    short pause; // update pause applied at the event
    short lock; // action-lock minimum; also the 0x7FFF rejection-count source
} ResponseMotionRow;

// Guarded-response row, indexed by Fighter.guard_response_index.
typedef struct GuardResponseRow {
    unsigned short flags;
    short event_gate;
    float planar_speed;
    float vertical_speed;
    float damping;
    float gravity_aux;
    short pause; // fallback when the attack pause is 0x7FFF
    short rejection; // rejection count when the attack staged none
    short lock; // action-lock minimum
    short phase_rate; // written into the first phase record's rate
} GuardResponseRow;

// Fractional integer-cursor block: action timelines and fighter countdowns.
typedef struct TimelineBlock {
    unsigned short reserved;
    unsigned short flags; // 0x1/0x2 whole unit extracted or assigned, 0x4 pending activation (current holds -N), 0x8 cleared by advance
    int assigned; // value of the last explicit assignment
    int previous; // previous integer, refreshed when a whole unit is extracted
    int current; // current integer cursor or count
    float previous_position;
    float position; // current + remainder
    float predicted; // next position; countdowns clamp at zero
    float remainder;
    void *type; // 0x005DA070
} TimelineBlock;

typedef struct PadRecord {
    PadDmaSnapshot *dma_area;
    int last_state;
    PadPacket packet;
    unsigned char actuator_bytes[6];
    unsigned char actuator_state;
    unsigned char vibration_depth;
    VibrationEntry vibration[4];
    unsigned char actuator_failures;
    unsigned char pressure_configured;
    unsigned char cached_mode;
    unsigned char configuration_state;
    unsigned char repeat_counter;
    unsigned char configuration_retries;
    unsigned char _unknown_0046; // opaque; poll preserves only low two bits
    unsigned char port;
    unsigned char slot;
    unsigned char left_magnitude;
    unsigned char right_magnitude;
    unsigned char _pad_004B[0x1];
    float left_angle; // radians
    float right_angle; // radians
    unsigned char pressure[12];
    unsigned int previous_public_held; // late normal-frame-gated snapshot
    unsigned int held; // native active-high mask
    unsigned int pressed; // ~previous & current
    unsigned int released; // previous & ~current
    unsigned int repeat; // repeat stream after a 15-update hold delay
    unsigned int raw_held_history; // used by resident edge production
} PadRecord;

// Battle input history record; 0x18 bytes, the last two unused.
typedef struct InputRecord {
    unsigned int held; // native mask
    unsigned int pressed; // current & ~previous
    unsigned int released; // previous & ~current
    float left_angle; // radians
    float right_angle; // radians
    unsigned char left_magnitude; // normalized
    unsigned char right_magnitude;
    unsigned char _pad_0016[0x2];
} InputRecord;

typedef struct Fighter {
    unsigned int node_flags; // 0x02 enables the fighter update slots

    unsigned int node_reset_word_04;

    unsigned int node_reset_word_08;

    int node_kind;

    int root_selector;

    void * node_identifier;

    struct Fighter * previous;
    unsigned char _pad_001C[0x4];
    struct Fighter *opponent; // paired fighter
    struct BattleInput *input; // battle input object

    BattleField * field;

    void * graph_link_2c;
    float position[4];
    float orientation[4]; // +0x08 is the yaw used by the view-relative input angle
    void *vtable; // slot 0x1C is the character AI wrapper
    unsigned char _pad_0054[0xC];
    unsigned char control_flags; // with state_flags read as one halfword, bits 5..8 suppress logical input
    unsigned char state_flags; // 0x08 timed downed recovery enabled; 0x80 fixed hit gravity
    unsigned char status_flags; // 0x01 no statistics, no exchange; 0x20 slow downed profile; 0x01 also suppresses ordinary awakening dispatch
    unsigned char contact_flags; // 0x01 routed this update, 0x40 side contact, 0x80 grounded; 0x10 Gaara/Deidara special state, 0x20 awakening controller marker
    unsigned char ceiling_flags; // 0x01 ceiling contact
    unsigned char _pad_0065[0x3];
    int character_id; // live identity copied from the selected character record
    float hp; // normalized HP
    float chakra;
    float support_gauge; // linked support resource, not guard durability
    float support_recovery;
    float staged_chakra; // staged chakra amount for jutsu selection
    short staged_tier;
    short staged_lifetime; // reservation countdown, starts at 60
    short staged_lockout; // post-release staged-input lockout, 60 when requested
    unsigned char _pad_0086[2];
    unsigned int random_word; // one unconditional shared MT draw per maintenance pass
    int copied_character_id; // +0x8C from character record
    char *character_display_name;
    char *body_filename;
    void *palette_names /* contiguous name records, 30 chars per record */;
    void *texture_names /* contiguous name records, 30 chars per record */;
    void *model_names /* contiguous name records, 30 chars per record */;
    char *effect_anchor_name;
    void *character_callbacks;
    unsigned char _unknown_00ac[8];
    int authored_action_count;
    ActionRecord *default_actions; // character's default action array

    ActionRecord *alternate_actions;
    unsigned char _unknown_00c0[4];
    int authored_row_count;
    CharacterAnimationRow *default_rows;
    CharacterAnimationRow *working_rows;
    unsigned char _unknown_00d0[4];
    int authored_animation_count;
    char **animation_names;
    void **animation_working_array;
    unsigned char _unknown_00e0[4];
    float contact_height; // +0xE4; scaled by capture_uniform_scale for probes
    union { void *event_callback; float contact_width; }; // +0xE8; retain existing callback view
    float ground_target;
    float ground_acceleration;
    float ground_braking;
    float motion_scale; // native motion scalar; recovery impulses use 3 * this as gravity
    float effect7d_motion_value; // +0xFC; effect 0x7D writes 2.5
    float recovery_planar_speed; // ACT_RCV_0 planar target
    float effect7d_motion_scale_a; // +0x104; effect 0x7D halves on each construction
    float effect7d_motion_scale_b; // +0x108; effect 0x7D halves on each construction
    int jump_preparation; // +0x10C; primary action-cursor threshold
    float first_jump_height;
    float second_jump_height; // +0x114
    int x_dash_startup; // +0x118 signed primary-cursor startup threshold
    int x_dash_duration; // +0x11C signed primary-cursor movement duration
    float x_dash_min_distance; // +0x120 opponent-target lower bound
    float x_dash_max_distance; // +0x124 target upper bound and category-2 threshold sentinel replacement
    unsigned char _pad_0128[0x10];
    float capture_range; // +0x138 centered-distance eligibility bound
    float capture_distance_cap; // +0x13C computed-approach displacement cap
    unsigned char _pad_0140[8];
    float offense;
    float durability;
    float knockback_taken; // receiver factor, clamped to 0..2
    float knockback_given; // source factor
    float effect_countdown_scale; // +0x158; gameplay meaning beyond countdown normalization unresolved
    float item_emission_scale; // delayed kind-6 emission count and spacing
    float hp_recovery;
    float chakra_recovery;
    unsigned char staged_input_inhibit; // manager key 5 is zero
    unsigned char chakra_debit_inhibit; // manager key 2 is nonzero; only value 1 blocks debit
    unsigned char _pad_016A[2];
    float handicap_attack;
    float handicap_defense;
    unsigned char _pad_0174[0x10];
    short jutsu_selector[2]; // configured jutsu selectors for records 0..3
    short jutsu_slot_config; // retained slot among 4..9
    unsigned short selected_jutsu_effect;
    short chakra_cost_tier; // authored tier 0/1/2 maps to raw 5/10/15
    short major_state; // 5 ordinary hit, 6 timed downed recovery, 8 action
    short substate; // ordinary response 0x27..0x5C, downed 0x5D..0x62, guard 5..7
    short phase; // phase within the current action
    short exchange_phase;
    short exchange_phase_counter;
    unsigned char _pad_0198[2];
    short voice_event_cooldown; // decremented once per admitted housekeeping call
    short chakra_shortage_sound_cooldown; // unscaled per-update countdown at 0x19C
    unsigned char _pad_019E[2];
    float chakra_history_old; // last eligible crossing old sample; debits write 15
    float chakra_history_new; // last eligible crossing new sample
    unsigned char chakra_full_feedback; // feedback latch, initialized/rearmed 1 and consumed 0
    unsigned char _pad_01A9[3];
    float update_rate; // advances the timelines and the action lock; 1.0 in majors 5 and 6 unless overridden
    float update_rate_override; // replaces the effect factor when not 1.0
    float update_rate_multiplier; // multiplies update_rate when not 1.0
    TimelineBlock primary_timeline; // action cursor; zeroed on state entry
    TimelineBlock secondary_timeline; // advances at update_rate * secondary_rate
    TimelineBlock update_pause; // decrements by 1.0; positive suspends action updates
    TimelineBlock hit_rejection; // decrements by 1.0 without a pause; positive makes router modes 0, 2, 3 discard hits
    TimelineBlock action_lock; // decrements by update_rate after the pause; action entry waits for zero

    TimelineBlock embedded_block_26c;

    TimelineBlock embedded_block_290;
    unsigned char _pad_02B4[0xc];
    float tracking_position[4];
    unsigned char _pad_02D0[0x10];
    float capture_scale[3]; // +0x2E0 axis scales used by full-transform attachment
    unsigned char _pad_02EC[4];
    float capture_uniform_scale; // +0x2F0 geometry height/width scale
    unsigned char _pad_02F4[0x14];
    unsigned short paired_transition_flags; // +0x308; zero advances substitution phases
    short presentation_factor_duration; // +0x30A
    unsigned int presentation_factor_work; // +0x30C
    float presentation_factor; // +0x310
    float presentation_factor_target; // +0x314
    short paired_transition_remaining; // +0x318; zero advances substitution phases
    short presentation_amount_duration; // +0x31A
    short presentation_amount_work; // +0x31C
    short presentation_amount; // +0x31E
    unsigned int presentation_style; // +0x320
    short target_section;
    short facing; // 1 swaps requested Right/Left in ccCommand matching
    float paired_target_angle; // +0x328
    float opponent_distance; // planar distance refreshed by fighter_refresh_opponent_geometry
    float effect4a_distance; // +0x330; effect 0x4A admission upper bound 400
    float opponent_vertical_delta; // +0x334 selected opponent target Z minus own Z
    unsigned int logical_input; // copied from BattleInput.logical_mask
    float stick_magnitude;
    float stick_angle;
    InputSample input_history[32]; // appended after the timelines advance
    int input_history_index;
    unsigned char _pad_04C8[0x8];
    float transient_input_motion[4]; // +0x4D0; added to movement and cleared after the slot
    float transient_motion[4]; // per-update displacement addition, cleared after movement
    StatPair stats[24]; // 12 input recoveries, 18 ordinary hits, 19 guarded hits
    short action_statistics[63][5];
    unsigned char _pad_07c6[2];
    void *recovery_source; // retained recovery source; not cleared by response exits
    ActionRecord *recovery_record; // retained recovery record

    GenericNode embedded_node;
    unsigned char _pad_0824[0xc];
    unsigned char recovery_grounded; // grounding saved with the recovery source
    unsigned char _pad_0831[0xF];
    float placement_history[8][4]; // native placement fills all eight with current position
    int placement_history_index; // ring index 0..7, advances once per maintenance pass
    int effect_count;
    void *effects; // effect nodes; ID at +0x68, countdown at +0x6C
    void *effect_tail;

    void * effect_vtable;
    struct Fighter *effect_owner; // gameplay container owner
    void *effect_sidecar; // allocated for classes 1 and 2

    void *effect_sidecar_head;
    void *effect_sidecar_tail;
    void * secondary_effect_vtable;
    short last_effect_id; // initialized -1; successful insertion updates it; removal never clears it
    unsigned char _pad_08EA[0x2];
    float status_display_delta;
    float status_display_value;
    unsigned int status_display_style;
    unsigned char _pad_08F8[0x20];
    short input_params_shadow[12]; // copy of the hold/release and multi-press parameters

    unsigned char _pad_0930[0x20];
    FighterHandleList * owned_handle_list;
    unsigned char _pad_0954[0x2];
    unsigned short action_progress_blocker; // action-progress gate requires zero
    unsigned char _pad_0958[0x2];
    short guard_state; // below 1 ordinary response, 1 or more guarded response, -1 guard bypass
    short guard_input_timing;
    short guard_response_index; // guarded-response row
    short response_4f_stage; // private stage of response 0x4F
    short response_4f_stage_count; // per-stage invocation count of response 0x4F
    short substitution_route; // +0x964; stored route, including internally added facing bit 0x100
    short substitution_phase; // +0x966; native phases 1..7
    short substitution_phase_calls; // +0x968; previous-call count controls phase departure
    unsigned char _pad_096A[6];
    float previous_position[4]; // +0x970; maintenance snapshot
    short previous_movement_facing; // +0x980
    short previous_placement_facing; // +0x982
    short previous_response_facing; // +0x984
    short previous_contact_side; // +0x986
    short physics_mode; // +0x988; shared movement selector
    short bridge_output_age; // cleared when the input bridge suppresses output
    short movement_facing; // 0/1 used by AI facing correction
    short placement_facing; // derived with movement_facing and response_facing from placement yaw
    short response_facing;
    unsigned char aerial_steering_variant; // +0x992
    unsigned char _pad_0993;
    float response_planar_speed; // oriented planar speed
    float response_vertical_speed;
    float smoothed_input_speed; // +0x99C; separate from actual planar speed
    float attack_scale; // attack knockback scale; reset to 1.0 after use
    float saved_attack_scale; // attack_scale saved at the motion event
    float planar_scale; // transient planar scale; reset to 1.0 after use
    float vertical_scale; // transient vertical scale; reset to 1.0 after use
    float landing_vertical_speed; // vertical speed saved on first grounding
    float next_gravity; // gravity for the next movement pass; reset to 1.0 after it
    unsigned char reaction_variant; // low two bits choose the reaction family; AI tests >1
    unsigned char _pad_09B9;
    short action_motion_class; // +0x9BA common action/X-dash motion classification
    short action_motion_stage; // +0x9BC motion-stage gate
    short x_dash_saved_direction; // +0x9BE direction retained at preparation entry
    short x_dash_cooldown; // unscaled per-update countdown at 0x9C0
    short action_motion_updates; // +0x9C2 unscaled invocation counter
    short action_motion_countdown; // +0x9C4 authored motion counter
    unsigned char _pad_09C6[2];
    float x_dash_motion_accumulator; // +0x9C8 delta-scaled movement envelope angle
    unsigned char _pad_09CC[4];
    float x_dash_start_position[4]; // +0x9D0 saved preparation-entry position
    float x_dash_target_position[4]; // +0x9E0 mutable movement target
    short section_transfer_delta;
    short section_transfer_stage; // +0x9F2
    short section_transfer_calls; // +0x9F4
    short section; // stage section
    short section_transfer_saved_section; // +0x9F8
    unsigned char _pad_09FA[2];
    float section_transfer_visual_increment; // +0x9FC
    float section_transfer_visual_position[4]; // +0xA00
    float section_transfer_origin[4];
    float section_transfer_destination[4];
    void *action_descriptor; // current action-descriptor row
    unsigned char _pad_0A34[0x4];
    short action_count;
    unsigned char _pad_0A3A[0x2];
    short current_action; // current action index
    short pending_action; // one pending action index; -1 empty
    unsigned char action_outcome;
    signed char previous_action_outcome; // +0xA41 prior contact outcome
    signed char action_outcome_auxiliary[3]; // +0xA42..+0xA44 optionally published with outcome
    signed char pending_combo_hits; // accepted hits consumed by the native combo object
    unsigned char approach_flags; // +0xA46 1 row motion,2 computed approach,4 gate lost
    unsigned char previous_approach_flags; // +0xA47 saved at primary event 0
    float approach_angle; // +0xA48 envelope angle advanced toward pi/2
    ActionRecord *current_record; // current action record
    ActionAttackBank *current_action_payload; // pointed word bit 0x10 gates AI exchange staging
    ActionRecord *actions; // working action array
    ActionRecord *initial_actions; // +0xA58; initialized with the selected working action base
    unsigned char _pad_0A5C[4];
    float action_entry_count; // +0xA60 contextual loop count for IDs 51/62
    float action_loop_auxiliary; // +0xA64 cleared by ID62
    float action_rate_addition_count; // +0xA68 ID62 event-count rate growth
    unsigned char _unknown_0A6C[0x1C];
    float action_second_entry_count; // +0xA88 ID77 action0x1B count
    unsigned char _unknown_0A8C[0x2C];
    float kidomaru_cycle_entry_count; // +0xAB8 action0x23 phase1 entries
    float kidomaru_cycle_limit; // +0xABC 2+8*charge ratio
    float kidomaru_cycle_charge_ratio; // +0xAC0 saved ratio
    unsigned char _unknown_0AC4[0x1C];
    float saved_response_position[4]; // restored by the held-response handoff
    float capture_target[4]; // +0xAF0 computed approach target, reused when refresh is ineligible
    unsigned int exchange_roles; // Extra Hit exchange roles; 0x100/0x400/0x1000 select modes 2 and 3
    unsigned char endpoint_corrected; // +0xB04
    unsigned char _pad_0B05[3];
    short exchange_count;
    short exchange_window; // interval for the opposite fighter's window progress
    float exchange_progress; // cached window progress
    short context_state; // positive value bypasses AI decision and dispatch after prepass

    short afterimage_marker;
    short sequence_camera_counter;
    unsigned char afterimage_flags;
    signed char afterimage_count;
    unsigned char afterimage_work;
    unsigned char _pad_0B19[7];
    float sequence_camera_anchor[4];
    union { FighterChildList * owned_child_list; FighterAuxiliaryPlayback *auxiliary_playback; }; // +0xB30 auxiliary player view
    short queued_chain; // retained direct-action chain; -1 none
    short chain_slots[4]; // category-indexed retained direct-action chain
    short chain_phase; // 0 starts the chain, 2 continues later categories
    short hold_cooldown; // approaches zero by one per synthesis call
    short hold_cooldown_reload;
    short hold_count;
    short hold_threshold;
    short hold_progress;
    short hold_progress_cap; // zero disables hold/release synthesis
    short hold_release_latch;
    short hold_overflow;
    short multi_press_threshold;
    short multi_press_distance; // inclusive window; default 12
    short multi_press_latch;
    unsigned char _pad_0B56[0x2];
    signed char paired_hit_marker; // router mode 2: 1 ordinary, -1 guarded, -2 intercepted
    unsigned char _pad_0B59[0x7];
    ActionRecord *streak_attack_record; // retained attack record for the streak overrides
    short response_streak; // consecutive ordinary responses; reset on leaving major 5
    short downed_auto_recovery; // automatic downed-recovery threshold
    short downed_input_recovery; // earliest input-driven downed-recovery threshold
    unsigned char _pad_0B6A[0x4];
    short response_repeat_count; // 0x3A/0x3B repeats, capped at 3
    short pending_item_code;
    short item_action_blocker;
    short item_use_work;
    short saved_item_use_work;
    short item_projectile_count; // accepted item uses and Tenten projectile creations, reset on awakening
    unsigned char _pad_0B7A[0xA];
    void **animations; // animation objects indexed by phase-record slot
    unsigned int animation_result; // nonzero once the animation ends
    short animation_slot; // current animation slot
    short previous_animation_slot; // +0xB8E last applied slot; mismatch triggers playback rebind
    unsigned short secondary_rate; // secondary timeline and animation rate, /256
    unsigned short animation_previous_frame; // +0xB92 unsigned saved whole frame
    short animation_start_frame;
    unsigned char animation_start_callback_enabled; // +0xB96 selects seek flag and initial command delivery
    union { unsigned char item_action_admission; unsigned char animation_wrap_count; }; // +0xB97 saturates at 0xFF
    unsigned char animation_wrap_notification; // +0xB98 set on frame decrease
    unsigned char _pad_0B99;
    short grounded_updates; // consecutive grounded updates; zero while airborne
    unsigned char ground_air_history; // 1 entered grounded, 2 entered airborne; 0x20/0x10 later changes
    unsigned char side_contact_active; // +0xB9D
    unsigned char _pad_0B9E;
    signed char contact_side; // +0xB9F; side-probe selector
    float side_probe_distance; // +0xBA0
    float floor_probe_distance; // +0xBA4; auxiliary ray, also updated by direct contact
    float ceiling_probe_distance; // +0xBA8
    unsigned int floor_probe_attributes; // +0xBAC; auxiliary flags, distinct from movement_flags
    unsigned int side_damage_attributes; // +0xBB0 bit0x400 selects contact damage0.04;
    unsigned int movement_flags; // navigation filter 0x800 and LandingTree admission mask 0x2000D801
    unsigned int polygon_attributes; // retained environment polygon word; wire requires full equality

    unsigned int ceiling_damage_attributes; // +0xBBC bit0x400 selects contact damage0.04
    unsigned char _pad_0BC0[0x10];
    unsigned char embedded_array_bd0[2][0x50];

    unsigned char _pad_0C70[4];
    void *contact_attack_source; // +0xC74 secondary fallback source
    void *contact_secondary_source; // +0xC78 paired secondary collision candidate
    unsigned char _pad_0C7C[4];
    union { unsigned char embedded_array_c80[2][0x50]; SupportAttackSample primary_attack_samples[2]; };

    void *auxiliary_attack_source; // +0xD20 auxiliary collision candidate
    void *auxiliary_secondary_source; // +0xD24 auxiliary secondary collision candidate
    unsigned char _pad_0D28[8];
    union { unsigned char embedded_array_d30[2][0x50]; SupportAttackSample auxiliary_attack_samples[2]; };

    union { unsigned char embedded_managed_dd0[0x24]; CollisionQueryList primary_collision_results; };

    union { unsigned char embedded_managed_df4[0x24]; CollisionQueryList secondary_collision_results; };

    union { unsigned char embedded_managed_e18[0x24]; CollisionQueryList auxiliary_collision_results; };
    unsigned int hit_request_bits; // +0xE3C collision/arbitration routing summary
    float contact_point[4]; // +0xE40 collision-derived retained contact position
    union { float loopy_motion_factor; ActionRecord *published_action_record; }; // +0xE50 retain Loopy Fist float view; attack publication writes current record
    ActionRecord *response_attack_record; // attack record of the active response
    void *response_source; // source object of the active response
    short attack_repeat_countdown; // retained repeat count from the attack record
    unsigned char _pad_0E5E[2];
    CcsContainer *shared_body_container;
    CcsContainer *body_container;
    void * owned_handle_e68; // owning optional handle
    void *model_collection; // borrowed foot-model bindings use this collection
    CcsAnimationPlayer * owned_animation_player; // +0xE70
    void * owned_handle_e74;
    void *appearance_material;
    void *appearance_palette;
    void *appearance_texture;
    unsigned char _pad_0E84[0x20];
    GenericList embedded_children; // +0xEA4
} Fighter;

typedef struct BattleInput {

    unsigned char node_flags;

    unsigned char _pad_0001[0x1];
    unsigned short live_marker;

    unsigned int node_reset_word_04;

    unsigned int node_reset_word_08;

    int node_kind;

    int root_selector;
    char *identifier; // controller1 for side 0, controller2 for side 1

    struct BattleInput * previous;

    struct BattleInput * next;
    Fighter *fighter; // owning fighter
    Fighter *opponent; // other fighter, for relative angles

    void * graph_links[2];

    unsigned char _pad_0030[0x20];
    void * vtable;
    unsigned char _pad_0054[0xc];
    int side; // zero-based controller side
    PadRecord *pad; // resident pad record: pad storage + 0x1C + side * 0x78
    short bindings[8]; // battle bindings, signed halfwords
    unsigned char _pad_0078[0x4];
    int pacing; // construction-time copy of the display-count pacing byte
    unsigned char _pad_0080[0x4];
    float facing_angle; // owning fighter's yaw relative to the view; selectors 14 and 15
    float opponent_angle; // opponent direction including elevation; selectors 6..9
    int alternate_valid; // gates alternate_angle; never written in retail
    float alternate_angle; // selectors 10..13; never written in retail
    InputRecord *records; // circular history
    int previous_index;
    int current_index;
    int capacity; // 300 / pacing
    float sector_threshold_45; // selectors 4 and 5; default about 5pi/6
    float sector_threshold_23; // selectors 2 and 3; default pi/2
    unsigned int logical_mask; // translated battle logical mask
    float stick_magnitude; // left-stick magnitude / 255
    float stick_angle; // left-stick angle from the current record
    unsigned char _pad_00B8[0x8];
} BattleInput;

// One step of a static ccCommand table; matched newest step first.
typedef struct CommandStep {
    int marker; // -2 suppresses the one-record advance after a match
    unsigned int mask; // requested native mask
    short word; // history word: 0 held, 1 pressed, 2 released
    short trials; // nearest-match trials
} CommandStep;

typedef struct CommandGroup {
    CommandStep *steps;
    int count;
} CommandGroup;

typedef struct CommandListEntry {
    char *name;
    short tokens[5];
    short padding;
} CommandListEntry;

typedef struct CommandListRow {
    char *name;
    int _unknown_04;
    int tokens[10];
    int token_count;
} CommandListRow;

typedef struct CommandList {
    unsigned char _pad_0000[0x2C];
    short row_count;
    short scroll;
    short visible_rows;
    unsigned char _pad_0032[0x6];
    CommandListRow rows[18];
} CommandList;

typedef struct StageLine {
    float endpoint_a[4];
    float endpoint_b[4];
    struct StageLine *next;
    unsigned int filter_flags;
    unsigned int section;
    unsigned int cached_attributes; // collision-polygon word; miss keeps previous value; semantic readers unresolved; exact head-table references are builders/midpoint/floor-profile/cleanup/getters, with two apparent first-head aliases from interaction-manager layout and one second-head alias from an absolute resource-name address; bounded live navigation 0x006F1180..0x007063DF has only a stack halfword scalar +0x2C read at 0x00700148 and no non-stack quadword +0x20/doubleword +0x28 load covering this word; partial/unaligned loads, arbitrary arithmetic and indirect readers remain open
} StageLine;

typedef struct StageEndpointPair {
    float endpoint_a[4];
    float endpoint_b[4];
} StageEndpointPair;

typedef struct StagePointerVector {
    unsigned int capacity;
    unsigned int size;
    void **data;
} StagePointerVector;

typedef struct StageSectionConfig {
    StagePointerVector *endpoint_pairs; // separately allocated StageEndpointPair objects; no cached-attribute tail
    unsigned char _pad_0004[0xC];
    float boundary_a[4];
    float boundary_b[4];
    float *boundary_a_ref;
    float *boundary_b_ref;
    float component0_span;
    unsigned char _pad_003C[0x4];
} StageSectionConfig;

typedef struct BgRecord {
    int owner_list; // sign-extended first source int16; named factories use 4
    int factory;
    int list_selector;
    char *configuration;
} BgRecord;

typedef struct BgObject {
    void *vtable;
    struct BgScene *scene;
    int owner_list;
    int factory;
    int list_selector;
    char *configuration;
    int draw_enabled; // +0x18, independent of update_enabled
    int update_enabled; // scene loops invoke virtual +8 only when nonzero
    struct BgObject *next_owned;
    unsigned char _pad_0024[0x4];
} BgObject;

typedef struct BgScene {
    unsigned int flags; // bits1/2/4/8 suppress object loops and auxiliary controllers
    unsigned char _pad_0004[0x4];
    float update_factor; // initialized 1.0; complete writer set unresolved
    unsigned char _pad_000C[0x24];
    float direction_offset; // +0x30
    float projection_scalar; // +0x34
    void *archive; // borrowed
    void *bgdata_object;
    unsigned char _pad_0040[0x4];
    void *selectors[12]; // non-owning registration/link owners
    unsigned char owning_lists[5][0x10]; // own object destruction
    BgRecord *records;
    unsigned char _pad_00C8[0x4];
    void *aux_cc;
    void *aux_d0;
    float fog_near_distance;
    float fog_far_distance;
    float fog_near_percentage;
    float fog_far_percentage;
    unsigned int fog_rgb; // low byte first
    unsigned char _pad_00E8[0x20];
    void *aux_108;
    void *selector_objects[12];
    unsigned char _pad_013C[0x4];
    void *vtable;
    unsigned char _pad_0144[0xC];
} BgScene;

typedef struct BgControl {
    void *archive; // borrowed lookup; stage_archive_handle owns release
    BgScene *scene;
    unsigned char stage_flags;
    unsigned char _pad_0009[0x3];
    int load_slot;
    int section_count;
    unsigned char _pad_0014[0xC];
    float boundary_min[4];
    float boundary_max[4];
    unsigned char _pad_0040[0x10];
    float camera_vector[4];
    unsigned char _pad_0060[0x80];
    short state_word;
    unsigned char _pad_00E2[0x2];
    int state_e4;
    int state_e8;
    unsigned char _pad_00EC[0xC];
    void *s15_animation;
    unsigned char _pad_00FC[0x934];
    void *vtable;
    unsigned char _pad_0A34[0xC];
    float section0_min[4];
    float section0_max[4];
    float section1_min[4];
    float section1_max[4];
    StagePointerVector section_configs;
    unsigned char first_head_count[2];
    unsigned char first_active_index[2];
    StageLine **first_heads[2];
    unsigned char second_head_count[2];
    unsigned char second_active_index[2];
    StageLine **second_heads[2];
    unsigned char _pad_0AA4[0xC];
    float player1_node[4];
    float player2_node[4];
} BgControl;

typedef struct BattleField {
    unsigned char _pad_0000[0x18];
    struct BattleField *previous;
    struct BattleField *next;
    unsigned char _pad_0020[0x30];
    void *vtable;
    unsigned char _pad_0054[0xC];
    unsigned char embedded_object_ctrl[0x10];
    BgControl *background;
    unsigned int reset_word74;
    unsigned int reset_word78;
    union { unsigned int background_snapshot; int section_count; }; // +0x7C
    unsigned int reset_word80;
    unsigned char reset_byte84;
    unsigned char _pad_0085[0xb];
} BattleField;

typedef struct StageAnchorRecord {
    float *side0_vectors;
    float *side1_vectors;
    unsigned char side0_count;
    unsigned char side1_count;
    unsigned char _pad_000A[0x6];
} StageAnchorRecord;

typedef struct StageRouteRecord {
    signed char source_line;
    signed char destination_line;
    unsigned char _pad_0002[0x2];
    float point_fraction;
    unsigned char action_type;
    unsigned char _pad_0009[0x3];
} StageRouteRecord;

typedef struct StageRenderDescriptor {
    unsigned char _pad_0000[0x24];
    float packet_coefficient; // copied to packet +0x204; original semantic name unresolved
    float color_coefficient; // multiplied by 128 and optionally opacity into color high byte
} StageRenderDescriptor;

// Resident CCS directory record; 0x38 bytes. Runtime pointer 4 denotes an unresolved reference.
typedef struct CcsRecord {
    char name[0x1E];
    unsigned char _pad_001E[2];
    char *namespace_name;
    struct CcsRecord *hash_next;
    unsigned short name_hash;
    unsigned short type_tag;
    void *runtime;
    void *secondary;
    void *transient_play_entry;
} CcsRecord;

typedef struct CcsNameQuery {
    char name[0x1E];
    unsigned char wildcard;
    unsigned char _pad_001F;
} CcsNameQuery;

typedef struct CcsPlayEntry {
    void *value;
    CcsRecord *provider;
    unsigned short type_tag;
    unsigned char flags;
    unsigned char _pad_000B;
    unsigned int type_specific;
} CcsPlayEntry;

typedef struct CcsObjectVector {
    void **pointers;
    int count;
} CcsObjectVector;

typedef struct CcsObjectSpec {
    char *container_spec;
    char *object_name;
} CcsObjectSpec;

typedef struct CcsReader {
    TransportDescriptor *read_descriptor;
    TransportDescriptor *write_descriptor;
    unsigned char *cursor;
    unsigned char *write_cursor;
    int read_total;
    int write_total;
    unsigned char *read_end;
    unsigned char *write_end;
    int producer_thread;
    int consumer_thread;
    int total_capacity;
    unsigned char *memory_start;
    unsigned char state;
    unsigned char owns_data;
    unsigned char aborted;
    unsigned char _unknown_0033;
    int chunk_size;
    unsigned short slot_count;
    unsigned char _unknown_003a[2];
    TransportDescriptor *descriptors;
} CcsReader;

typedef struct CcsContainer {
    struct CcsContainer *next;
    char name[0x20];
    unsigned int reference_flags;
    CcsRecord **hash_buckets;
    char *namespaces;
    CcsRecord *records;
    int namespace_count;
    int record_count;
    unsigned int *checkpoints;
    void *play_task;
    void *copy_fixups;
    void *dependency_groups;
    void *light_secondaries;
    void *object_secondaries;
    void *reference_links;
    void *generator_packets;
    void *ordered_controllers;
    CcsPlayEntry *play_entries;
    void *external_context;
    CcsReader *reader;
    CcsPointerVector relation_blocks;
    void *play_context;
    void *object_callback;
    float ambient_color[4];
    int frame;
    int last_frame;
    int checkpoint_count;
    short rate;
    short rate_remainder;
    unsigned int terminator_position;
    unsigned short play_control;
    unsigned short runtime_flags;
    unsigned char _pad_00A8[2];
    unsigned short parse_state;
    unsigned short version;
    unsigned short ownership_flags;
    unsigned char canceled;
    unsigned char _pad_00B1[0xF];
} CcsContainer;

typedef struct CcsLoadWrapper {
    AdxfHandle *file;
    unsigned int file_metadata;
    CcsReader *compressed_transport;
    CcsReader *reader;
    CcsUngzip *gzip_bridge;
    struct TaskCleanupRecord *gzip_task;
    int input_block_size;
    int output_block_size;
    unsigned short input_blocks;
    unsigned short output_blocks;
    void *transport_buffer;
    unsigned char canceled;
    unsigned char _pad_0029[3];
    unsigned char read_done;
    unsigned char gzip_done;
    unsigned char decode_done;
    unsigned char _pad_002F;
    CcsContainer *container;
} CcsLoadWrapper;

typedef struct CcsQueueNode {
    struct CcsQueueNode *next;
    char *path;
    unsigned int flags;
    unsigned short state;
    unsigned char _pad_000E[2];
    unsigned int file_size;
    CcsLoadWrapper wrapper;
} CcsQueueNode;

typedef struct CcsResidencyEntry {
    char name[0x20];
    unsigned char state;
    unsigned char allocation_origin;
    short use_count;
    struct CcsResidencyEntry *previous;
    struct CcsResidencyEntry *next;
} CcsResidencyEntry;

typedef struct CcsResidencyManager {
    unsigned char flags;
    unsigned char stop;
    unsigned char canceled;
    unsigned char _pad_0003;
    int entry_count;
    CcsResidencyEntry *head;
    CcsResidencyEntry *tail;
    CcsResidencyEntry entries[64];
    CcsResidencyEntry *free_entry;
    CcsLoadWrapper *active_wrapper;
    short activity_count;
    short batch_workers;
} CcsResidencyManager;

typedef struct CcsExternalRuntime {
    CcsRecord *record;
    CcsRecord *link;
    unsigned int preserved_08;
    unsigned char _pad_000C[4];
    CcsRecord *owner_link;
    unsigned int preserved_14;
    unsigned int preserved_18;
    unsigned int preserved_1C;
} CcsExternalRuntime;

typedef struct CcsCopyFixupNode {
    CcsRecord *source;
    struct CcsCopyFixupNode *next;
    CcsRecord *target;
    unsigned char _pad_000C[4];
    unsigned char payload[0x30];
} CcsCopyFixupNode;

typedef struct CcsStreamPathPair {
    char *first;
    char *stream_path;
} CcsStreamPathPair;

typedef struct SpSkillRequestRow {
    unsigned int display_word;
    char *main_path;
    unsigned char extra_count;
    unsigned char stream_count;
    unsigned char appearance_count;
    unsigned char _pad_000B;
    char **extra_paths;
    CcsStreamPathPair *stream_pair;
    union { unsigned int contest_word; struct SpSkillAppearanceRow *appearance_rows; };
} SpSkillRequestRow;

typedef struct CcsPlayRequest {
    char *path;
    unsigned int flags;
} CcsPlayRequest;

typedef struct CcsStreamRequest {
    char *path;
    CcsContainer *container;
    unsigned char retention;
    unsigned char _pad_0009[3];
    unsigned int flags;
    int transport_word;
} CcsStreamRequest;

typedef struct CcsStreamPlayer {
    void *decoded_backing;
    void *compressed_backing;
    CcsReader decoded_reader;
    CcsReader compressed_reader;
    void *begin_callback;
    void *frame_callback;
    void *callback_90;
    void *end_callback;
    struct TaskCleanupRecord *read_task;
    struct TaskCleanupRecord *decode_task;
    struct TaskCleanupRecord *gzip_task;
    int decoded_chunk_bytes;
    int compressed_chunk_bytes;
    short decoded_slots;
    short compressed_slots;
    int sector_bytes[16];
    CcsLoadWrapper *resident_wrappers[16];
    CcsStreamRequest requests[16];
    unsigned char _pad_0270[2];
    short request_count;
    short read_cursor;
    short gzip_cursor;
    short decode_cursor;
    unsigned char _pad_027A[2];
    unsigned short play_flags;
    unsigned char _pad_027E[3];
    unsigned char stop_latch;
    unsigned char skip_latch;
    unsigned char _unknown_0283[9];
    CcsUngzip ungzip;
    unsigned char _unknown_02d0[4];
    CcsPlayRequest *request_list;
    short request_list_count;
    unsigned char whole_file;
    unsigned char _pad_02DB;
    int skill;
} CcsStreamPlayer;

typedef struct CollisionSphere {
    int active;
    unsigned int receive_mask;
    unsigned int environment_mask;
    int environment_match_mode;
    unsigned int send_mask;
    struct CollisionSphere *next;
    float radius;
    float z_bias;
    float center[4];
    float correction[4];
    unsigned int environment_flags;
    unsigned char _unknown_0044[0xC];
} CollisionSphere;

typedef struct CollisionResult {
    unsigned int receiver_mask;
    unsigned int counterpart_mask;
    float counterpart_radius;
    float distance;
    float separation;
    struct CollisionQueryList *counterpart_list;
    unsigned char _unknown_0018[8];
    float counterpart_center[4];
    struct CollisionResult *next;
    unsigned int counterpart_generation;
    unsigned char _unknown_0038[8];
} CollisionResult;

typedef struct CollisionQueryList {
    int active;
    unsigned int result_mask;
    int result_count;
    int registration_count;
    struct CollisionQueryList *next_active;
    CollisionResult *results;
    struct CollisionRegistration *registrations;
    void *owner;
    unsigned int generation;
} CollisionQueryList;

typedef struct CollisionRegistration {
    int active;
    int activation_eligible;
    int owns_sphere;
    unsigned int result_mask;
    int result_count;
    CollisionResult *results;
    struct CollisionRegistration *next_active;
    struct CollisionRegistration *previous;
    struct CollisionRegistration *next;
    CollisionSphere *sphere;
    CollisionQueryList *owner_list;
    unsigned int receive_mask;
    unsigned int send_mask;
} CollisionRegistration;

typedef struct CollisionSnapshot {
    unsigned int receiver_mask;
    unsigned int counterpart_mask;
    float counterpart_radius;
    float distance;
    float separation;
    CollisionQueryList *counterpart_list;
    unsigned char _unknown_0018[8];
    float counterpart_center[4];
    CollisionQueryList *cached_list;
    unsigned int cached_generation;
    unsigned char _unknown_0038[8];
} CollisionSnapshot;

typedef struct SphereSnapshot {
    float center[4];
    float radius;
    unsigned char _unwritten_0014[0xC];
} SphereSnapshot;

typedef struct SphereSnapshotBank {
    SphereSnapshot spheres[64];
    int count;
    unsigned char _unknown_0804[0xC];
} SphereSnapshotBank;

typedef struct TrianglePrimitive {
    float aabb_min[3];
    unsigned int flags;
    float aabb_max[3];
    float plane_constant;
    float vertices[3][4];
    float normal[4];
    float edge_vectors[3][4];
    float edge_lengths[3];
    unsigned char _unknown_009C[4];
} TrianglePrimitive;

typedef struct EnvironmentBoundsHeader {
    float aabb_min[3];
    unsigned char _unknown_000C[4];
    float aabb_max[3];
    int count; // group count at root, primitive count in a packed group
} EnvironmentBoundsHeader;

typedef struct CollisionEnvironment {
    int active;
    struct CollisionEnvironment *next;
    int transform_mode;
    EnvironmentBoundsHeader *hierarchy;
    float local_to_world[3][4];
    float origin[4];
    float world_to_local[4][4];
    unsigned int enabled_groups;
    unsigned char _unknown_0094[4];
} CollisionEnvironment;

typedef struct EnvironmentCandidate {
    float point[4];
    float normal[4];
    float distance;
    int branch_class; // swept sphere only, observed 1..3
    int feature_selector; // swept sphere only, observed 0..3
    unsigned char _unwritten_002C[4];
    CollisionEnvironment *environment;
    unsigned char _unwritten_0034[0xC];
    int group_index;
    int primitive_index;
    unsigned int primitive_flags;
    unsigned char _unwritten_004C[4];
    float local_normal[4];
} EnvironmentCandidate;

typedef struct InteractionRecord {
    unsigned char _unknown_0000[4];
    char *resource_name;
    unsigned char _unknown_0008[8];
    unsigned int category;
    unsigned int flags;
    unsigned char _unknown_0018[0xC];
    float attack_scalar;
    float knockback_scale;
    unsigned char response_selector;
    signed char guard_selector;
    short repeat_count;
    short update_pause;
    short rejection_count;
    unsigned char _unknown_0034[0x20];
    short alternate_category;
    short update_form;
    unsigned int extended_58;
    unsigned int extended_5c;
    unsigned int relation_mask;
    unsigned int counterpart_mask;
} InteractionRecord;

typedef struct InteractionDefinition {
    char *resource_name;
    unsigned char control_definition_enabled; // +0x04 read by inherited primary slot0x204
    unsigned char _unknown_0005[3];
    unsigned int category;
    unsigned int flags;
    short update_form;
    short alternate_category;
    short response_selector;
    short guard_selector;
    float knockback_scale;
    unsigned int extended_5c;
    unsigned int relation_mask;
    unsigned int counterpart_mask;
    float attack_scalar;
    short repeat_count;
    short update_pause;
    short rejection_count;
    unsigned char copied_slots[0x10];
    unsigned char _unknown_0042[2];
} InteractionDefinition;

typedef struct InteractionHeader {
    struct InteractionHeader *self;
    void *active_context;
    InteractionRecord *active_record;
    unsigned int flags;
    InteractionRecord *built_record;
    InteractionDefinition *definition;
    int definition_index;
    void *context;
    InteractionRecord *record;
    short saved_repeat_count;
    unsigned char _unknown_0026[2];
    unsigned int accumulator_28;
    unsigned int accumulator_2c;
    unsigned int update_count;
    unsigned int accumulator_34;
    float saved_scalar;
    short alternate_category;
    short saved_category;
    unsigned char prepared;
    unsigned char explicit_definition;
    unsigned char _unknown_0042[2];
} InteractionHeader;

typedef struct ResponsePacket {
    unsigned char tag;
    unsigned char _private_0001[0xF];
    float anchor[4];
    float position[4];
} ResponsePacket;

typedef struct InteractionPending {
    void *participant;
    void *counterpart;
    InteractionRecord *record;
    unsigned char active;
    unsigned char _unknown_000D[3];
} InteractionPending;

typedef struct InteractionRegistryEntry {
    void *object;
    int generation;
} InteractionRegistryEntry;

typedef struct InteractionTuple {
    int slot;
    int generation;
    void *object;
} InteractionTuple;

typedef struct InteractionManager {
    InteractionRegistryEntry primary[2];
    InteractionRegistryEntry auxiliary[2][32];
    CutinController cutin; // +0x210
    unsigned char _unknown_0a54[0x20];
    unsigned char flags;
    unsigned char _unknown_0A75;
    short clash_timer;
    short clash_phase;
    short clash_counts[2];
    short clash_initial_bias;
    float camera_anchors[2][4];
    unsigned char _unknown_0AA0[0x60];
    float reconciled_position[4];
    unsigned char _unknown_0B10[0x40];
    unsigned int clash_input_mask;
    unsigned char _unknown_0B54[0xC];
    float packet_positions[2][4];
    InteractionPending pending[2];
    unsigned char _unknown_0BA0[8];
    InteractionRecord *record_banks[2][197];
    unsigned int primary_candidates[2];
    unsigned int auxiliary_candidates[2];
    unsigned char _unknown_11E0[0x40];
    SphereSnapshotBank sphere_banks[2][2];
    unsigned char _unknown_3260[8];
    int pending_combo_hits[2];
    int combo_countdown[2]; // +0x3270; maintenance decrements only on the masked non-flush route
    unsigned char _unknown_3278[0x54];
    void *offset_gauge_interface; // +0x32CC
    unsigned int control_dispatch_flags; // +0x32D0; inherited callback selection
    unsigned char _unknown_32D4[0x4C];
    void *interface;
    unsigned char _unknown_3324[0xC];
} InteractionManager;

typedef struct AiState {
    float movement_magnitude;
    float movement_angle;
    short target_facing;
    unsigned char _pad_000A[2];
    float opponent_distance;
    unsigned int logical_mask;
    unsigned char _pad_0014[8];
    Fighter *self;
    Fighter *target;
    short character_region_value;
    short alternate_target_threshold;
    unsigned char _pad_0028[8];
    int spatial_bucket;
    unsigned int state;
    int countdown;
    unsigned int route_submode;
    float cached_self_position[4];
    unsigned char _pad_0050[4];
    int world_object_handle;
    union { int secondary_handle; int item_slot; }; // item-use state stores a raw inventory slot
    int point_index;
    unsigned char _pad_0060[8];
    unsigned int target_source;
    unsigned char _pad_006C[4];
    float target_position[4];
    int target_region;
    int route_region;
    unsigned char _pad_0088[8];
    unsigned char request_latch;
    unsigned char _pad_0091[3];
    union {
        unsigned int cooldowns[31]; // offsets 0x94..0x10C; all nonzero entries decrement once per AI tick
        struct { unsigned char _linked_timer_prefix[0x60]; unsigned int linked_countdown; unsigned char _linked_timer_suffix[0x18]; };
    };
    int retry_countdown;
    int practice_jump_countdown;
    int practice_attack_countdown;
    unsigned char _pad_011C[8];
    unsigned char collision_candidate;
    unsigned char attack_candidate;
    unsigned char support_candidate; // scripted tail writes; ordinary reactions do not refresh it
    unsigned char _pad_0127[1];
    int special_action_cooldown;
    unsigned char _pad_012C[0x18];
    int point_near_deadline;
    int point_far_deadline;
    unsigned char _pad_014C[2];
    signed char linked_partner_type;
    unsigned char _pad_014F;
    short linked_handshake;
    unsigned char _pad_0152[0xE];
    short parameters[40];
    int cached_action_index;
    int phase_cursors[3];
    unsigned char _pad_01C0[0x20];
} AiState;

typedef struct AiCharacterValues {
    short region_value;
    short alternate_target_threshold;
} AiCharacterValues;

typedef struct AiCharacterDescriptor {
    unsigned short value; // can be 0xFFFF while flags are nonzero
    unsigned char flags; // 1 scales p16, 4 p8, 8 p24; 0x10 participates in state-22 gates
    unsigned char _pad_0003[1];
} AiCharacterDescriptor;

typedef struct AiWorldObjectRecord {
    unsigned char kind;
    unsigned char _pad_0001[0xF];
    float position[4];
    unsigned int region;
    unsigned int source_word; // copied from world object +0x04
} AiWorldObjectRecord;

typedef union AwakeningAssociationValue {
    unsigned int inline_effect;
    unsigned short *effects;
} AwakeningAssociationValue;

typedef struct AwakeningAssociation {
    AwakeningAssociationValue value;
    int count; // zero ignores the value; one uses the inline ID; larger counts use the array
} AwakeningAssociation;

typedef struct AwakeningTrigger {
    short presentation_selector; // -1 disables the optional request; all other active retail rows use 0x1F
    unsigned char flags;
    unsigned char reserved; // zero in all 94 retail rows
} AwakeningTrigger;

typedef struct AwakeningAltitude {
    float upward_increment;
    float downward_increment;
    float upward_limit;
    float downward_limit;
    float substate_four_downward_limit;
    float return_increment;
    float major_four_return_increment;
} AwakeningAltitude;

typedef struct UltimateJutsuRecord {
    char *display_name;
    short authored_id;
    short category;
    unsigned char record_class;
    signed char cost_tier; // +0x09; 0/1/2 maps to chakra 5/10/15
    short intro_voice; // +0x0A
    short secondary_intro_voice; // +0x0C
    unsigned short effect;
    short damage_percent; // +0x10; multiplied by 0.01
    unsigned char _pad_0012[2];
} UltimateJutsuRecord;

typedef struct CharacterDefinition {
    void *factory;
    void *record;
} CharacterDefinition;

typedef struct BattleCharacterSlot {
    unsigned char flags;
    unsigned char _pad_0001[0x3];
    int character_id;
    int pending_character_id;
    int color;
    int first_animation_selector;
    int second_animation_selector;
    int selected_jutsu_record;
    int ultimate_mode; // cached raw Battle/Practice Ultimate setting
    int selected_support;
    unsigned int support_selector;
} BattleCharacterSlot;

typedef struct BattleConfiguration {
    unsigned char _pad_0000[0x28];
    BattleCharacterSlot sides[2];
    union {
        unsigned char trailing[3];
        struct {
            unsigned char active_load_slot;
            unsigned char stage_config_unknown; // lifecycle meaning unresolved
            unsigned char pending_load_slot;
        };
    };
    unsigned char _pad_007B;
} BattleConfiguration;

typedef struct BattleManager {
    unsigned char flags;
    unsigned char _pad_0001[3];
    struct SaveProfile *profile;
    int phase;
    int mode;
    int cached_overlay_selector; // -1 at construction; published after full load and constructors
    int menu_state;
    int active_side;
    int control_mode;
    BattleConfiguration current;
    BattleConfiguration saved;
    unsigned char _pad_0118[0xA8];
    void *scratch;

    unsigned char _pad_01C4[0x830];
    PracticeSettingsPack practice;
    PracticeSettingsPack alternate_settings;
    unsigned char default_settings_prefix[7];
    unsigned char difficulty;
    unsigned char default_settings_suffix[4];
    unsigned char _pad_0a18[0x3bc];
    void *front_end_render_context;
    void *front_end_transition_owner;
    void *battle_conditions;
    Fighter * reserved_fighter_alias;
    Fighter *fighters[2];
    BattleInput * input_aliases[3]; // index0 reserved, side+1 used
} BattleManager;

typedef struct AwakeningPauseGate {
 unsigned int flags;
 signed char character_id[2];
 signed char appearance_id[2];
 unsigned char side_flags[2];
 unsigned char _unknown_000a[2];
 signed char mode;
 signed char selector;
 signed char stage;
 unsigned char _unknown_000f;
 signed char lifecycle; // 0 inactive, 1 construction pending, 2 child active; dispatch also tolerates -1
 unsigned char _unknown_0011;
 unsigned short suppression_first_third;
 unsigned short suppression_second;
 unsigned char _unknown_0016[2];
 short presentation_index;
 short retained_index;
 void *child;
 unsigned char _unknown_0020[0x200];
 void *branch_pointer0;
 void *branch_pointer1;
 unsigned char _unknown_0228[0xc];
 void *branch_resource;
 unsigned char _unknown_0238[0x388];
 void *presentation_handles[4];
 unsigned char _unknown_05d0[0x80];
 ToneShadeRandomDestination tone_destination;
 ToneShadeRandomAnimator tone_animator;
 signed char request_filter;
 unsigned char _unknown_0695[3];
 float tone_accumulator0;
 float tone_accumulator1;
 unsigned char _unknown_06a0[0x20];
} AwakeningPauseGate;

typedef struct DeidaraVariant {
    unsigned char _pad_0000[0x1110];
    void *ordinary_animations;
    unsigned char _pad_1114[0x482C];
    unsigned char mode;
    unsigned char _pad_5941[0x3];
    void *alternate_animations;
} DeidaraVariant;

typedef struct GaaraVariant {
    unsigned char _pad_0000[0xEE0];
    void *ordinary_animations;
    unsigned char _pad_0EE4[0x48FE];
    unsigned char mode;
    unsigned char _pad_57E3[0x5];
    void *alternate_animations;
} GaaraVariant;

typedef struct ChojiVariant {
    unsigned char _pad_0000[0x6238];
    unsigned char mode;
} ChojiVariant;

typedef struct ProjectileConfig {
    short external_id;
    unsigned char class_selector;
    unsigned char _pad_0003[0x1];
    short profile_index;
    short constructor_value;
    signed char constructor_count;
    unsigned char activation_selector;
    unsigned char _pad_000a[0x2];
    float scalar;
    unsigned int helper_word;
    unsigned char config14;
    unsigned char action_selector;
    unsigned char response16_selector;
    unsigned char response17_selector;
    unsigned char contact_selector;
    unsigned char _pad_0019[0x3];
    float initial_scalar;
    unsigned char notification_mode;
    unsigned char service_mode_selector;
    unsigned char _pad_0022[0x2];
    float extent_a;
    float extent_b;
    short position_service_id;
    unsigned char player_scalar_enabled;
    unsigned char contact_filter;
    short emission_sound; // external-ID emitter reads this signed sound at +0x30
    unsigned char response32_selector;
    unsigned char _pad_0033[0x1];
    unsigned char flags;
    unsigned char _pad_0035[0x3];
    int value38;
    int value3c;
    int value40;
    int value44;
    float value48;
    unsigned char _pad_004c[0x4];
    short helper_byte_source;
    unsigned char _pad_0052[0x12];
    float helper_scalar;
} ProjectileConfig;

typedef struct Projectile {
    unsigned char _pad_0000[0xc];
    unsigned int object_kind;
    unsigned char _pad_0010[0x20];
    float position[4];
    unsigned char _pad_0040[8];
    float direction_scalar;
    unsigned char _pad_004c[4];
    void * vtable;
    unsigned char _pad_0054[0xc];
    struct Projectile * next;
    void * primary_service;
    void * secondary_service;
    void * handle;
    void * notification;
    ProjectileConfig * config;
    short config_index;
    short external_id;
    short class_selector;
    short state;
    unsigned char service_mode;
    unsigned char setup81;
    short state_count;
    short delay;
    unsigned char linked;
    unsigned char first_activation;
    unsigned char initialized;
    unsigned char activated;
    signed char side_tag;
    unsigned char _pad_008b[0x1];
    unsigned int serial;
    float spawn_position[4];
    float spawn_vector2[4];
    float post_spawn_vector[4];
    unsigned char _pad_00c0[0x10];
    float orientation_scalar;
    unsigned char _pad_00d4[0xc];
    float orientation[4];
    float direction[4];
    float transform[16];
    unsigned char _pad_0140[0x40];
    float notification_transform[16];
    float state_vector[4];
    float state_vector2[4];
    float scalar1;
    float scalar2;
    float scale;
    float transition_scalar;
    unsigned char same_section;
    unsigned char transient_flag;
    unsigned char _pad_01f2[6];
    short exposed_countdown;
    unsigned char _pad_01fa[2];
    float accumulator;
    short active_count;
    unsigned char opposite_section;
    unsigned char _pad_0203;
    short angular_rate;
    unsigned char service_enabled;
    unsigned char contact_phase_enabled;
    unsigned char config14;
    unsigned char _pad_0209[3];
    unsigned int action_callback_trigger; // value 1 invokes the root action callback
    short service_state;
    short active_service_id;
    short retiring_service_id;
    unsigned char optional_service_enabled;
    unsigned char _pad_0217[0x1];
    void * nodes;
    unsigned char _pad_021c[0x18];
    unsigned char node_service_argument;
    unsigned char _pad_0235[7];
    unsigned int contact_flags[2];
    unsigned char child_marker;
    unsigned char _pad_0245[3];
    short lineage_count;
    short lineage_key;
    unsigned int lineage_word;
    unsigned char lineage_consumed;
    unsigned char _pad_0251[0x7];
    float config_scalar;
    short retirement_count_override;
    unsigned char bound;
    unsigned char stored_target;
    unsigned char _pad_0260[8];
    short local_phase;
    unsigned char local_mode;
    unsigned char _pad_026b[2];
    unsigned char homing_mode;
    unsigned char _pad_026e[0x2];
    short retirement_gate;
    unsigned char contact_admission; // +0x272 returned by projectile_contact_admitted unless state-gated
    unsigned char retirement_requested;
    union { void *auxiliary_allocation; ActionRecord *attack_record_override; }; // +0x274 borrowed record view used by transient_record_get
    float accumulator_step;
    unsigned char adaptive_step;
    unsigned char commit_enabled;
    unsigned char _pad_027e[2];
    unsigned int smoke_count;
    unsigned char support_notify;
    unsigned char _pad_0285[0x3];
    unsigned int support_identifier;
    unsigned char combo_publication_suppressed; // +0x28C; exactly 1 skips response34 contribution
    unsigned char _pad_028d[3];
} Projectile;

typedef struct ProjectileProfile {
    unsigned char _pad_0000[0x1];
    unsigned char service_mode;
    short active_service_id;
    short retiring_service_id;
    unsigned char _pad_0006[0x6];
} ProjectileProfile;

typedef struct ProjectileLineageSlot {
    unsigned short age;
    short key;
    unsigned int word;
    unsigned char consumed;
    unsigned char _pad_0009[0x3];
} ProjectileLineageSlot;

typedef struct ProjectileManager {
    unsigned char _pad_0000[0xc];
    int count;
    unsigned int next_serial;
    Projectile * head;
    Projectile * tail;
    void * service;
    unsigned char update_disabled;
    unsigned char service_disabled;
    unsigned char _pad_0022[2];
    float maximum_x;
    float minimum_x;
    unsigned char _pad_002c[0x38];
    ProjectileLineageSlot lineage[2][4];
    unsigned char _pad_00c4[4];
    float side_steps[2];
} ProjectileManager;

typedef struct ProjectileWeightedEntry {
    signed char emitter_kind;
    unsigned char _pad_0001[0x3];
    int argument;
    signed char weight;
    unsigned char _pad_0009[0x3];
} ProjectileWeightedEntry;

typedef struct ProjectileScheduleEntry {
    short threshold;
    short config_index;
    unsigned char _pad_0004[0x1c];
} ProjectileScheduleEntry;

typedef struct AwakeningEffectRecord {
    void *factory;
    int effect;
    int default_lifetime;
    unsigned int flags;
    float attack_factor;
    float defense_factor;
    float action_rate;
    float payload_1c;
    float payload_20;
    float payload_24;
    float payload_28;
    float payload_2c;
    float payload_30;
    float payload_34;
    float payload_38;
    float payload_3c;
    float payload_40;
    float payload_44;
    float hp_delta;
    float hp_boundary;
    float chakra_delta;
    float chakra_boundary;
    EffectDisplayDescriptor *display_descriptor;
    int presentation_selector;
    unsigned char _pad_0060[4]; // next record's unknown leading word
} AwakeningEffectRecord;

typedef struct AwakeningCharacterRecord {
    int character_id;
    char *display_name;
    char *body_filename;
    void *palette_names /* contiguous name records, 30 chars per record */;
    void *texture_names /* contiguous name records, 30 chars per record */;
    void *model_names /* contiguous name records, 30 chars per record */;
    char *effect_anchor_name;
    void *callbacks;
    unsigned char _pad_0020[8];
    int action_count;
    ActionRecord *default_actions;
    ActionRecord *alternate_actions;
    unsigned char _pad_0034[4];
    int row_count;
    CharacterAnimationRow *default_rows;
    CharacterAnimationRow *working_rows;
    int animation_count;
    char **animation_names;
    void **animation_working_array;
    unsigned char _pad_0050[8];
    float contact_height; // +0x58
    float contact_width; // +0x5C
    float ground_target;
    float ground_acceleration;
    float ground_braking;
    float gravity_factor; // +0x6C; ordinary decrement *3*rate*multiplier
    float terminal_factor; // +0x70; unit-multiplier terminal magnitude *3
    float aerial_target; // +0x74
    float aerial_steering; // +0x78
    float aerial_braking; // +0x7C
    int jump_preparation; // +0x80
    float first_jump_height;
    float second_jump_height; // +0x88
    int x_dash_startup; // +0x8C signed startup cursor threshold
    int x_dash_duration; // +0x90 signed movement cursor duration
    float x_dash_min_distance; // +0x94 copied to Fighter.x_dash_min_distance
    float x_dash_max_distance; // +0x98 copied to Fighter.x_dash_max_distance
    unsigned char _pad_009C[0x20];
    float offense;
    float durability;
    unsigned char _pad_00C4[0x10];
    float hp_recovery;
    float chakra_recovery;
} AwakeningCharacterRecord;

typedef struct CcsFrameCommand {
    struct CcsFrameCommand *next;
    unsigned int value1;
    unsigned int value2;
    unsigned int frame;
    void *target;
    unsigned short type_tag;
    unsigned char _pad_0016[2];
} CcsFrameCommand;

typedef struct CcsPlayContext {
    unsigned char _pad_0000[0xC];
    CcsFrameCommand *queued_commands;
    unsigned char _pad_0010[0xE4];
    void *default_controller;
    void *default_extended_controller;
    unsigned char _pad_00FC[0x14];
    void *scene_environment;
    void *action_manager;
    unsigned char _pad_0118[8];
} CcsPlayContext;

typedef struct CcsExternalPlayContext {
    unsigned char _pad_0000[0xE0];
    CcsFrameCommand *queued_commands;
} CcsExternalPlayContext;

typedef struct CcsRuntimeRecordPrefix {
    CcsRecord *record;
} CcsRuntimeRecordPrefix;

typedef struct CcsModelMesh {
    unsigned char _pad_0000[4];
    CcsRecord *material_record;
    unsigned int vertex_count; unsigned short packet_bytes; unsigned char _unknown_000e[2]; void *packet;
    short *positions;
    unsigned int *elements;
    unsigned int *uv_words; unsigned int *auxiliary_attributes; unsigned char *strip_controls; void *index_entries;
    unsigned int auxiliary_count;
    void *geometry;
    void *projection_geometry;
    unsigned int projection_geometry_size;
    unsigned char _pad_003C[4];
} CcsModelMesh;

typedef struct CcsModelRuntime {
    CcsRecord *record; void *bounds;
    CcsModelMesh *meshes;
    float position_scale; void *children; unsigned short child_count;
    unsigned short mesh_count; unsigned int runtime_flags; unsigned int ownership_flags; unsigned char _unknown_0020[0x10]; unsigned long long blend_state; unsigned char _unknown_0038[8]; struct CcsExtraPassOwner *extra_pass_owner;
} CcsModelRuntime;

typedef struct CcsScenePlayTarget {
    float world_matrix[16]; float local_matrix[16];
    void *parent;
    float inherited_factor; // +0x84
    float alpha;
    unsigned char alpha_flags; unsigned char matrix_dirty;
    unsigned short type_tag;
    CcsRecord *source_record;
    CcsModelRuntime *model;
    struct CcsMorpherRuntime *morph_controller;
    void *auxiliary; // resolved secondary shadow model for a 0x0100 child
    void *transform_attachment; unsigned char _unknown_00a4[4];
    unsigned char flags;
} CcsScenePlayTarget;

typedef struct CcsExtendedController {
    struct CcsExtendedController *next;
    union {
        struct { unsigned char _pad_0004[0x48]; struct RendererTransformState *renderer; };
        struct { unsigned char _unknown_0004[0xC]; BattleHudRenderContext ordered_base; };
    }; // ordered_base +0x10; renderer +0x4C
    CcsProjectionBucket buckets[15];
    unsigned char _pad_0140[0x10];
    CcsProjectionBucket *queue_head;
    unsigned short bucket_count;
    unsigned short color_address;
    unsigned short depth_address;
    unsigned char width_log2;
    unsigned char height_log2;
    unsigned char mode;
    unsigned char alpha;
    unsigned char composite_passes;
    unsigned char offset_multiplier;
    float direction[4];
    float projection_scalar;
    float parameter;
} CcsExtendedController;

typedef struct CcsOrderedControllerTable {
    unsigned char _pad_0000[8];
    void *default_extended;
    void *default_lightweight;
} CcsOrderedControllerTable;

typedef struct CcsImageTransferGroup {
    unsigned char _pad_0000[8];
    char name[0x20];
    void *image_members;
    void *clut_members;
    struct CcsImageTransferGroup *next;
    unsigned char _pad_0034[4];
} CcsImageTransferGroup;

typedef struct CcsAnimationDescriptor {
    unsigned char _pad_0000[8];
    CcsContainer *container;
    unsigned int frame_count;
    unsigned char _pad_0010[4];
    unsigned char *reader_start;
    AnimationTrackPair *track_pairs;
    unsigned int track_count;
    unsigned int lighting_color; // 0x80000000 leaves shared lighting unchanged
    unsigned short *relations;
    unsigned short flags;
    unsigned char _pad_002A[2];
} CcsAnimationDescriptor;

typedef struct GenericNode {
    unsigned char flags;
    unsigned char _pad_0001;
    unsigned short live_marker; // 0x474F while constructed
    unsigned int reset_word_04;
    unsigned int reset_word_08;
    int node_kind;
    int root_selector; // base -1; initial camera root 0
    void *identifier;
    struct GenericNode *previous;
    struct GenericNode *next;
    void *graph_links[4]; // borrowed subclass cross-links
    union { unsigned char _pad_0030[0x10]; float position[4]; };
    union { unsigned char reset_bytes[0x10]; float orientation[4]; };
    NodeMethods *vtable;
} GenericNode;

typedef struct GenericList {
    unsigned int count;
    GenericNode *head;
    GenericNode *tail;
    void *vtable;
} GenericList;

typedef struct CameraRegistry {
    GenericList nodes;
    GenericNode *current;
    GenericNode *previous;
} CameraRegistry;

typedef struct FighterCoordinator {
    GenericList nodes;
    unsigned char _pad_0010[4];
    int state;
    int local_state;
    int local_counter;
    int local_word;
    Fighter *participants[2]; // borrowed
    struct CoordinatorAuxiliaryB0 *auxiliary_b0; // owned
    void *auxiliary_3c; // owned
} FighterCoordinator;

typedef struct BattleHub {
    CameraRegistry *camera;
    GenericList *input;
    FighterCoordinator *fighters;
    GenericList *field;
} BattleHub;

typedef struct BattleState {
    unsigned char flags;
    unsigned char _unknown_0001;
    unsigned short first_phase_mask;
    unsigned short second_phase_mask;
    unsigned short first_phase_filter;
    unsigned short second_phase_filter;
    short inner_state;
    unsigned short entry_type;
    unsigned char _unknown_000e[2];
    int inner_delay;
    GenericNode *camera_root; // borrowed
    BattleHub *hub; // owned
    void *camera_controller;
    void *item_manager;
    struct BattleTopPanel *top_panels[2]; // owned per-side HUD panels
    void *clock;
    BattlePresentationRoot *presentation_root;
    void *auxiliary;
} BattleState;

typedef struct CameraNode {
    GenericNode node;
    unsigned char _pad_0054[0xC];
    unsigned char current;
    unsigned char _pad_0061[0x43];
    void *engine_camera; // owned 0x50-byte allocation
    void *output; // borrowed shared output, also lookup key
} CameraNode;

typedef struct DeferredChild {
    unsigned char state; // 1 released, >=2 recyclable
    unsigned char _pad_0001[0x2B];
    void *parent_data; // borrowed parent +0x180
    unsigned char _pad_0030[0x18];
    struct DeferredChild *next;
} DeferredChild;

typedef struct DeferredChildOwner {
    unsigned int count;
    DeferredChild *head;
} DeferredChildOwner;

typedef struct SupportSideRecord {
    unsigned char color;
    unsigned char linked_mode; // Manual 0, Auto 1
    unsigned char recharge_class;
} SupportSideRecord;

typedef struct SupportGeneration {
    void *vtable;
    unsigned int candidate;
    unsigned char reuse;
    unsigned char _pad_0009[3];
} SupportGeneration;

typedef struct SupportObject {
    GenericNode node;
    unsigned char _pad_0054[0xC];
    unsigned char selector;
    unsigned char _pad_0061[0xB];
    void *archive; // borrowed loaded archive
    void *player; // owned 0x120-byte handle
    void *handle_a0; // owned
    void *handle_50; // owned
    unsigned char _pad_007C[4];
    void *animations[5]; // borrowed ent, nut, run, act, ext payloads
    void *auxiliary_resource; // +0x94 borrowed attachment resource used by auxiliary slots
    unsigned char animation_selector;
    unsigned char _pad_0099[0xF];
    float facing_angle; // +0xA8 support facing helper result
    unsigned char _pad_00AC[4];
    float movement[4];
    unsigned char _pad_00C0[0x20];
    float playback_rate;
    unsigned char side;
    unsigned char _pad_00E5[1];
    unsigned char reason; // AI reacts to raw reasons 0..2; scripted support candidate requires 2
    unsigned char _pad_00E7[1];
    short ready_countdown; // reason 1 is ready only at zero
    unsigned char _pad_00EA[2];
    unsigned int state_cursor;
    unsigned char skip_advance;
    unsigned char animation_complete;
    unsigned char lifecycle; // 2 requests slot destruction
    unsigned char _pad_00F3[5];
    unsigned int previous_cursor;
    unsigned char _pad_00FC[4];
    unsigned char cursor_changed;
    unsigned char _pad_0101[7];
    unsigned int accumulator;
    unsigned char _pad_010C[4];
    unsigned char accumulator_changed;
    unsigned char _pad_0111[3];
    short contact_activation_countdown;
    unsigned char hit_notifications;
    unsigned char _pad_0117;
    unsigned char approach_flags[2];
    unsigned char _pad_011A[6];
    unsigned int generation;
    unsigned char _pad_0124[0xC];
    float reaction_range; // AI compares self-to-support distance with this
    void *children[5]; // owned, virtual deleting destructor
    union { unsigned char embedded_owner_148[0x28]; SupportCollection attack_collection; };
    union { unsigned char elements_170[6][0x50]; SupportAttackSample attack_samples[6]; };
    char *attack_names[6];
    union { unsigned char embedded_owner_368[0x28]; SupportCollection secondary_contact_collection; };
    union { unsigned char elements_390[3][0x50]; SupportAttackSample contact_samples[3]; };
    char *contact_names[3];
    union { unsigned char embedded_owner_48c[0x24]; struct { unsigned char _unknown_contact_0000[8]; int contact_result_count; unsigned char _unknown_contact_000C[0x18]; }; };
    unsigned char element_4b0[0x50];
    unsigned char managed_object_500[0xC];
    unsigned char lineage_flags;
    unsigned char _pad_050D[3];
} SupportObject;

typedef struct SupportOwner {
    void *vtable;
    SupportObject *slots[2];
    SupportSideRecord sides[2];
    unsigned char _pad_0012[2];
    SupportGeneration generation;
    unsigned char one_shot;
    unsigned char _pad_0021[3];
} SupportOwner;

typedef struct SupportCounters {
    short creations;
    short reasons;
    short lineage;
} SupportCounters;

typedef struct FighterListOwner {
    GenericList primary;
    unsigned int reset_word_10;
    GenericList secondary;
} FighterListOwner;

typedef struct FighterHandleListNode {
    unsigned char _pad_0000[0xC];
    void *referenced_handle; // cleanup use does not establish ownership
    unsigned char _pad_0010[4];
    void *owned_handle;
    struct FighterHandleListNode *next;
} FighterHandleListNode;

typedef struct FighterHandleList {
    unsigned char _pad_0000[4];
    FighterHandleListNode *head;
} FighterHandleList;

typedef struct FighterChildListNode {
    void *owned_handle;
    unsigned char _pad_0004[8];
    struct FighterChildListNode *next;
} FighterChildListNode;

typedef struct FighterChildList {
    void *owned_handle;
    unsigned char _pad_0004[0xC];
    FighterChildListNode *head;
} FighterChildList;

typedef struct FighterId78 {
    unsigned char _pad_0000[0x6254];
    void *owned_children[2];
    unsigned char _pad_625C[4];
} FighterId78;

typedef struct FighterId80 {
    unsigned char _pad_0000[0x6210];
    void *owned_children[3];
    void *owned_pair_621c[2];
    void *owned_pair_6224[2];
    unsigned char _pad_622C[4];
} FighterId80;

typedef struct FighterId92 {
    unsigned char _pad_0000[0x5300];
    void *owned_children[3];
    unsigned char _pad_530C[4];
} FighterId92;

typedef struct RegisteredActorReference {
    int index;
    unsigned int serial;
    void *actor;
} RegisteredActorReference;

typedef struct SkillHnw001 {
    unsigned char _pad_0000[4];
    int call_counter;
    int state;
    unsigned char _pad_000C[0x104];
    void *vtable;
    unsigned char _pad_0114[0x30];
    SharedSkillInputEvent *input_event; // +0x144
    unsigned short total_input_events; // +0x148
    short pending_hit_count;
    unsigned short input_event_age; // +0x14C
    unsigned short input_event_age_limit; // +0x14E
    unsigned char input_enabled;
    unsigned char _pad_0151[0x9F];
    void *container;
    unsigned char _pad_01F4[0x128];
    Fighter *linked_fighter; // +0x31C
    unsigned char _pad_0320[0x30];
    int side; // +0x350
    unsigned char _pad_0354[0x178];
    Fighter *target; // +0x4CC
    unsigned char _pad_04D0[0x30];
    int opposite_side; // +0x500
    unsigned char _pad_0504[0x35];
    unsigned char target_valid; // +0x539
    unsigned char _pad_053A[0x32];
    unsigned int resource_index;
    unsigned char _pad_0570[0xA80];
    void *animations[5];
    void *player; // owned
    RegisteredActorReference children[2]; // retirement is generation checked
    unsigned char interaction_records_a[2][0x50];
    unsigned char interaction_records_b[2][0x50];
    RegisteredActorReference independent_child;
    unsigned char _pad_116C[4];
    short counting_counter;
    short local_hit_count;
    unsigned char descriptor_threshold_reached; // update_count >= saved_repeat_count in accepted-event receiver
    unsigned char accepted_event;
    unsigned char finish_event;
    unsigned char finish_requested;
    unsigned char _pad_1178[8];
} SkillHnw001;

typedef struct CcsGeneratorPacket {
    CcsRecord *record;
    struct CcsGeneratorPacket *next;
    CcsRecord *animation_record;
    unsigned short count;
    unsigned char _pad_000E[2];
    CcsGeneratorPacketEntry entries[1];
} CcsGeneratorPacket;

typedef struct CcsActionRunner {
    struct CcsActionRunner *next;
    CcsGeneratorPacket *packet;
    unsigned short count;
    unsigned char _pad_000A[2];
    CcsGeneratorAction *actions;
} CcsActionRunner;

typedef struct CcsRelationData {
    struct AttachmentParameters *relations_a;
    struct AttachmentCollisionParameters *relations_b;
    short count_a;
    short count_b;
} CcsRelationData;

typedef struct BgTransition {
    BgObject base;
    void * endpoint_a;
    void * endpoint_b;
    unsigned char _pad_0030[0x10];
    float origin[4];
    float radius;
    float blend;
    float frame_override;
    float animation_multiplier;
    float cached_default_step;
} BgTransition;

typedef struct BgTransition2 {
    BgTransition base;
    float target_frame;
} BgTransition2;

typedef struct BgBreakObject {
    BgObject base;
    void ** models;
    int model_count;
    int active_model;
    int break_count;
    int break_threshold;
    unsigned char _pad_003c[0x4];
    unsigned char combatant_receiver[0x90];
    unsigned char query_receiver[0x90];
    unsigned char transform_block[0x10];
    unsigned char effect_block[0x10];
    int playback_state;
    int section_key; // used by CrashBreak subclass
    unsigned char _pad_0188[0x8];
} BgBreakObject;

typedef struct BgBreakAnimation {
    BgObject base;
    int rebirth_state;
    int remaining_rebirths;
    int rebirth_timer;
    float playback_rate;
    float opacity;
    void ** models;
    int model_count;
    int active_model;
    int break_count;
    int break_threshold;
    unsigned char _pad_0050[0x140];
    int playback_state;
    unsigned char _pad_0194[0xC];
} BgBreakAnimation;

typedef struct BgBreakReborn {
    BgBreakObject base;
    unsigned char _pad_0190[0x4];
    int remaining_rebirths;
    unsigned char _pad_0198[0x8];
} BgBreakReborn;

typedef struct BgElectricWire {
    BgObject base;
    unsigned int polygon_attributes;
    unsigned char _pad_002c[0x28];
    int interior_node_count;
    unsigned char _pad_0058[0x8];
    void * node_positions;
    void * node_velocities;
    void * node_work;
    unsigned char _pad_006c[0x28];
    int fighter_node[2];
    unsigned char _pad_009c[0x34];
    float endpoint_a[4];
    float endpoint_b[4];
    void * segments;
    unsigned char geometry_dirty;
    unsigned char _pad_00f5[0xB];
} BgElectricWire;

typedef struct BgWireSegment {
    unsigned char _pad_0000[0x180];
    void * environment;
    unsigned char _pad_0184[0xC];
    unsigned int polygon_attributes; // +0x190; authored word supplied to both generated triangles
    unsigned char _pad_0194[0xC];
    float endpoint_a[4];
    float endpoint_b[4];
    void * visual_model;
    unsigned char _pad_01c4[0x2C];
} BgWireSegment;

typedef struct BgLandingTree {
    BgObject base;
    int model_count;
    void * models;
    float current_center[4];
    float original_center[4];
    int sample_index;
    float width;
    float height;
    unsigned char fighter_latch[2];
    unsigned char _pad_005e[0x6];
    float amplitude;
    unsigned char _pad_0068[0x10];
    float vertical_displacement;
    unsigned char _pad_007c[0x4];
} BgLandingTree;

typedef struct BgHadesSnake {
    BgObject base;
    void * model;
    void * animations[10];
    unsigned char _pad_0054[0x1];
    unsigned char state;
    unsigned char state_aux1;
    unsigned char state_aux2;
    ActionRecord attack;
    unsigned char _pad_00ac[0x4];
    unsigned char attack_source[0x60];
    unsigned char attack_receiver[0x90];
    unsigned char reaction_receiver[0x90];
    unsigned char _pad_0230[0x20];
} BgHadesSnake;

typedef struct BgChandelier {
    BgObject base;
    unsigned char _pad_0028[0xC];
    float playback_rate;
    unsigned char _pad_0038[4];
    void **models;
    int model_count;
    int active_model;
    int broken;
    int break_threshold;
    unsigned char break_receiver[0x90];
    unsigned char swing_receiver[0x90];
    unsigned char impact_receiver[0x90];
    ActionRecord attack;
    unsigned char _pad_0254[0xC];
    unsigned char attack_source[0x60];
    unsigned char _pad_02c0[0x20];
    int playback_state;
    unsigned char _pad_02e4[4];
    int state;
    unsigned char _pad_02ec[0x54];
    int impact_ticks;
    unsigned char _pad_0344[0xC];
} BgChandelier;

typedef struct BgCraneTruck {
    BgObject base;
    unsigned char _pad_0028[0x4];
    void * model_controller;
    void * animation_a0;
    void * animation_a1;
    BgBreakObject * linked_break;
    unsigned char _pad_003c[0x4];
} BgCraneTruck;

typedef struct BgFootprintNode {
    unsigned char active;
    unsigned char _pad_0001[0x3];
    void *model;
    unsigned char _pad_0008[0x8];
    float reserved_vector[4];
    float opacity;
    float opacity_limit;
    float fade_decrement;
    void *vtable;
} BgFootprintNode;

typedef struct CcsAnimationPlayer {
    unsigned char _pad_0000[0x3C];
    void *renderer; // +0x3C borrowed drawing renderer selected around submission
    unsigned char _unknown_0040[0x48];
    float opacity;
    unsigned char _pad_008C[4];
    CcsAnimationDescriptor *animation;
    unsigned short step;
    unsigned short fraction;
    AnimationFrameIndex frame_index; // whole-frame consumers read either word or halfword
    unsigned char _pad_009C[4];
    CcsReader reader;
    CcsFrameCommand *queued_commands;
    struct CcsCompositionListNode *composition_children;
    void *command_callback;
    unsigned int cursor;
    unsigned int next_boundary;
    unsigned char _unknown_00f4[2]; unsigned char name_offset;
    unsigned char completion_flags;
    void *completion_stream;
    CcsPlayEntry *play_entries;
    void *scene_traversal; unsigned char _pad_0104[4];
    CcsContainer *container;
    struct EngineBattleCamera *camera;
    struct RendererTransformState *renderer_copy;
    AnimationBlendHeader *blend;
    unsigned char _unknown_0118[8];
} CcsAnimationPlayer;

typedef struct BgSuspensionBridge {
    BgObject base;
    unsigned char _pad_0028[0x4];
    void *nodes;
    void *ropes;
    void *helpers;
    unsigned char _pad_0038[0x8];
    int section_key;
    unsigned char _pad_0044[0x4C];
    float oscillation_step;
    float oscillation_amplitude;
    unsigned char _pad_0098[0x8];
} BgSuspensionBridge;

typedef struct BgHandRowShip {
    BgObject base;
    void *model_a;
    void *model_b;
    unsigned char _pad_0030[0x20];
    float center[4];
} BgHandRowShip;

typedef struct BgTumbleGrass {
    BgObject base;
    unsigned char _pad_0028[0x4];
    void *clumps;
    void *variant_resources;
} BgTumbleGrass;

typedef struct BgEscapeBird {
    BgObject base;
    void *child;
    unsigned char _pad_002C[0x24];
} BgEscapeBird;

typedef struct BgFootmarks {
    BgObject base;
    unsigned int surface_selection;
    unsigned char _pad_002C[0x3C4];
    int fighter_bound[2];
} BgFootmarks;

typedef struct BgMangrove {
    BgLandingTree base;
    unsigned char _pad_0080[0x10];
    void *derived_models;
} BgMangrove;

typedef struct AwakeningEffectNode {
    GenericNode base;
    unsigned char _pad_0054[0xC];
    int removal_reason; // written even when destruction is blocked
    Fighter *owner;
    int effect;
    int lifetime; // positive countdown, -1 authored indefinite, -2 protected inherent state
    unsigned int flags;
    float attack_factor;
    float defense_factor;
    float action_rate;
    float payload_80;
    float payload_84;
    float payload_88;
    float payload_8c;
    float payload_90;
    float payload_94; // chakra recovery deviation is this value minus 1
    float payload_98;
    float payload_9c;
    float payload_a0;
    float payload_a4; // signed chakra delta applied during construction before insertion
    float payload_a8; // signed chakra delta applied only at countdown zero
    float hp_delta;
    float hp_boundary;
    float chakra_delta;
    float chakra_boundary;
    unsigned char _pad_00BC[0x4];
} AwakeningEffectNode;

typedef struct ChojiActionPayload {
    unsigned char _pad_0000[0x70];
    float mode_value; // action 0x13 mode 0/1 uses 80/150; units unresolved
} ChojiActionPayload;

typedef union AnimationFrameIndex {
    unsigned int word;
    unsigned short whole;
} AnimationFrameIndex;

typedef struct CollisionSkillPrimary {
    unsigned char _unknown_0000[0xc];
    InteractionManager * manager;
    unsigned char _unknown_0010[0x4];
    unsigned char status_flags;
    unsigned char _unknown_0015[0xf0];
    unsigned char camera_record_disabled;
    unsigned char _unknown_0106[2];
    PresentationCameraRecord *camera_record;
    unsigned char _unknown_010c[4];
    void * interface;
    unsigned char _unknown_0114[0xc];
    InteractionTuple registry;
    unsigned char _unknown_012c[0x18];
    void *damage_event_source; // +0x144 shared-float admission
    unsigned char _unknown_0148[2];
    unsigned short damage_event_count; // +0x14A
    unsigned char _unknown_014c[0x90];
    int selector;
    unsigned char _unknown_01e0[0x20];
    InteractionHeader primary_header;
    unsigned char _unknown_0244[0xd8];
    Fighter * entity;
    void * resource;
    void * alternate_resource;
    unsigned char _unknown_0328[0x8];
    float position[4];
    unsigned char _unknown_0340[0x8];
    float anchor_direction;
    unsigned char _unknown_034c[0x4];
    int side;
    unsigned char _unknown_0354[0x35];
    unsigned char entity_link_valid;
    unsigned char _unknown_038a[0x26];
    InteractionHeader secondary_header;
    unsigned char _unknown_03f4[0xd8];
    Fighter *damage_target; // +0x4CC
    unsigned char _unknown_04d0[0x14];
    float anchor_y;
    unsigned char _unknown_04e8[0x18];
    int opposite_side; // +0x500
    unsigned char _unknown_0504[0x35];
    unsigned char damage_target_valid; // +0x539
    unsigned char _unknown_053a[0x32];
    int resource_index;
    unsigned char _unknown_0570[0x20];
    unsigned char camera_event_active;
    unsigned char control_dispatch_active; // +0x591
    unsigned char control_mask_active; // +0x592
    unsigned char _unknown_0593;
    int camera_variant;
    unsigned char _unknown_0598[0x5c];
    unsigned char damage_ready; // +0x5F4 TYO000B gate
    unsigned char _unknown_05f5[3];
    int clash_outcome;
    unsigned char _unknown_05fc[4];
    CollisionSnapshot snapshots[4][9];
    unsigned char _unknown_0f00[6];
    unsigned char clash_flags;
    unsigned char _unknown_0f07;
    short clash_count_a;
    short clash_count_b;
    unsigned int published_category;
    unsigned char _unknown_0f10[0x20];
    CollisionQueryList query_lists[5];
    unsigned int candidates;
    int packet_neighbor_counter;
    unsigned char packet_tag;
    unsigned char _unknown_0fed[0x3];
    InteractionTuple auxiliary_output;
    unsigned char _unknown_0ffc[0x4];
} CollisionSkillPrimary;

typedef struct CollisionSkillAuxiliary {
    unsigned char update_flags;
    unsigned char _unknown_0001[0xb];
    int class_id;
    unsigned char _unknown_0010[0x4];
    char * identifier;
    unsigned char _unknown_0018[0x18];
    float position[4];
    float orientation[4];
    void * interface;
    unsigned char _unknown_0054[0x14];
    InteractionManager * manager;
    InteractionTuple primary_registry;
    InteractionTuple registry;
    unsigned char _unknown_0084[0xc];
    int resource_index;
    unsigned char _unknown_0094[0xac];
    CollisionQueryList query_lists[4];
    unsigned int candidates;
    unsigned int accepted_contact_flags;
    unsigned int result_credit_count;
    void *pending_record; // +0x1DC
    unsigned char _unknown_01e0[0x10];
    CollisionSnapshot snapshots[3][9];
    unsigned char status_flags;
    unsigned char _unknown_08b1[0x4f];
    InteractionHeader primary_header;
    Fighter * entity;
    Fighter * alternate_entity;
    unsigned char _unknown_094c[0xc];
    int side;
    unsigned char _unknown_095c[0x34];
    InteractionHeader secondary_header;
    Fighter * height_entity;
    void * height_context;
    unsigned char _unknown_09dc[0x14];
    float wall_reference_x;
    unsigned char _unknown_09f4[0x2c];
    unsigned char alternate_update_flags;
    unsigned char _unknown_0a21;
    short alternate_phase_counter; // +0xA22
    unsigned char _unknown_0a24[0x8c];
    float anchor_span_x;
    float anchor_span_z;
    unsigned char _unknown_0ab8[0x8];
    float anchor_offset[4];
    int retirement_countdown; // +0xAD0
    int phase_counter; // +0xAD4
    int submission_pause;
    float fractional_step; // +0xADC
    float attack_scalar;
    unsigned char update_control;
    unsigned char packet_tag;
    unsigned char _unknown_0ae6[0xa];
    void * environment_resources;
    unsigned char _unknown_0af4[0x8];
    void * anchor_resource;
    unsigned char _unknown_0b00[0x4];
    void * publication_context;
    unsigned char _unknown_0b08[0x18];
    float direct_damage; // +0xB20 guard-sensitive contribution
    unsigned char _unknown_0b24[8];
    int computed_record_state;
    unsigned char _unknown_0b30[0x8];
    float wall_anchor_x;
    unsigned char _unknown_0b3c[0x4];
    CollisionSphere sphere;
    unsigned char _unknown_0b90[0x48];
    short computed_record_selector;
    unsigned char _unknown_0bda[0x2];
    int computed_update_state;
    unsigned char _unknown_0be0[0x160];
    float cache_center[4];
    unsigned char _unknown_0d50[0x30];
    float anchor_position[4];
    unsigned char _unknown_0d90[0x20];
} CollisionSkillAuxiliary;

typedef struct CollisionEntityScalars {
    unsigned char _unknown_0000[0xe4];
    float height;
    float width;
    unsigned char _unknown_00ec[0x204];
    float scale;
} CollisionEntityScalars;

typedef struct CollisionTransform {
    float world[4][4];
    float local[4][4];
    void * parent;
    unsigned char _unknown_0084[0x9];
    unsigned char dirty;
    unsigned char _unknown_008e[0x2];
} CollisionTransform;

typedef struct SkillAnchor1008 {
    unsigned char _unknown_0000[0x1008];
    float extent_x;
    float extent_z;
} SkillAnchor1008;

typedef struct SkillFirAnchor {
    unsigned char _unknown_0000[0x1018];
    float offset_x;
    float offset_z;
} SkillFirAnchor;

typedef struct SkillSakAnchor {
    unsigned char _unknown_0000[0x1038];
    float extent_x;
} SkillSakAnchor;

typedef struct SkillNewAnchor {
    unsigned char _unknown_0000[0x1248];
    float extent_x;
} SkillNewAnchor;

typedef struct SkillSswAnchor {
    unsigned char _unknown_0000[0x1130];
    float direction;
} SkillSswAnchor;

typedef struct SkillTyoAnchor {
    unsigned char _unknown_0000[0xff4];
    float offset_x;
} SkillTyoAnchor;

typedef struct SkillAnbAnchor {
    unsigned char _unknown_0000[0x1034];
    char * resource_name;
} SkillAnbAnchor;

typedef struct SkillKiwAnchor {
    unsigned char _unknown_0000[0x10a8];
    float extent_x;
} SkillKiwAnchor;

typedef struct SkillKibCenters {
    unsigned char _unknown_0000[0x1030];
    float first[4];
    unsigned char _unknown_1040[0x40];
    float second[4];
    unsigned char _unknown_1090[0x20];
    float entity_position[4];
} SkillKibCenters;

typedef struct ProjectileVtable {
    void *class_handle;
    void *reserved04;
    void *deleting_destructor;
    void *reserved0c[4];
    void *motion;
    void *reserved20;
    void *contact_response;
    void *motion_secondary;
    void *activation_setup;
    void *action_response;
    void *reserved34[4];
    void *update;
    void *service;
    void *reserved4c;
    void *activate;
    void *post_spawn;
    void *response58;
    void *response5c;
    void *reserved60;
    void *impact;
    void *bind_resource;
} ProjectileVtable;

typedef struct ProjectileHomingDelay {
    Projectile base;
    int phase;
    int phase_count;
    float value3c;
    float value40;
    float value48;
    float turn_amount;
    int post_spawn_count;
    unsigned char _pad_02ac[4];
} ProjectileHomingDelay;

typedef struct ProjectileLunEmitter {
    Projectile base;
    int child_config;
    short count;
    short delay_bound;
    float cursor;
    float speed_spread;
    float speed_multiplier;
    float spread_multiplier;
    unsigned char _pad_02a8[8];
    float spread_or_speed;
    unsigned char _pad_02b4[0xc];
} ProjectileLunEmitter;

typedef struct ProjectileServiceNode {
    struct ProjectileServiceNode *next;
    float scalar;
    unsigned char _pad_0008[8];
    float transform[16];
} ProjectileServiceNode;

typedef struct ProjectileNotification {
    unsigned char detached;
    unsigned char inactive;
    unsigned char _pad_0002[6];
    unsigned int service_word;
    unsigned char _pad_000c[0x20];
    void *transform;
    unsigned char _pad_0030[0x1c];
} ProjectileNotification;

typedef struct ProjectileHandle {
    unsigned char _pad_0000[0x1c];
    Projectile *projectile;
    unsigned char _pad_0020[4];
} ProjectileHandle;

typedef struct ProjectileHelper {
    unsigned char _pad_0000[0x18];
    unsigned int config_word;
    unsigned char _pad_001c[0xc];
    float scalar;
    unsigned char selector;
} ProjectileHelper;

typedef struct ProjectileHandleEntry {
    unsigned char _pad_0000[0x2c];
    unsigned int side_word;
    unsigned int secondary_word;
} ProjectileHandleEntry;

typedef struct ProjectileChar {
    Projectile base;
    void *resource290;
    void *service;
    void *pointer_array;
    unsigned char _pad_029c[0xc];
    int setup_index;
    unsigned int flags;
    int horizontal_mode;
    unsigned char _pad_02b4[0x14];
    float gravity_scale;
    int direction;
    unsigned int contact_flags;
    unsigned char _pad_02d4[0x15c];
    int index430;
    int index434;
    unsigned int reset_words[8]; // +0 clock (signed), +4 selected header, +8 retained resource word, +C row index, +10 command table, +14 resource table, +18 horizontal speed, +1C vertical speed
    float scalar; // gravity multiplier at +0x458; reset to 1 after integration
    short setup_count;
    unsigned char enabled;
    unsigned char _pad_045f[1];
    void *naruto_resource;
    void *naruto_service;
    unsigned char _pad_0468[8];
} ProjectileChar;

typedef struct ProjectileThrowSkill {
    unsigned char _pad_0000[0x124];
    unsigned int lineage_word;
    unsigned char _pad_0128[0x1f8];
    void *service;
    unsigned char _pad_0324[0x2c];
    int side;
    unsigned char _pad_0354[0x218];
    int lineage_key;
    unsigned char _pad_0570[0xa88];
    unsigned int emission_count;
    unsigned char _pad_0ffc[0xe2];
    unsigned char emission_latch;
    unsigned char _pad_10df[0x31];
    short schedule_index;
    short schedule_group;
} ProjectileThrowSkill;

typedef struct ProjectileWeightedSkill {
    unsigned char _pad_0000[0x124];
    unsigned int lineage_word;
    unsigned char _pad_0128[0x228];
    int side;
    unsigned char _pad_0354[0x218];
    int key;
    unsigned char _pad_0570[0xa80];
    short counter;
    short interval;
    signed char attempts;
    signed char attempt_limit;
    unsigned char _pad_0ff6[2];
    short start_threshold;
    short setup_halfword;
    unsigned char _pad_0ffc[4];
    ProjectileWeightedEntry *entries;
    short entry_count;
} ProjectileWeightedSkill;

typedef struct CcsRelationRuntime {
    unsigned char _pad_0000[0x18];
    CcsRelationData *relations;
} CcsRelationRuntime;

typedef struct CcsDependencyGroup {
    CcsRecord *source;
    struct CcsDependencyGroup *next;
    unsigned short count;
    unsigned char flags;
    unsigned char _pad_000B;
    CcsRecord **records;
    short *index_map;
} CcsDependencyGroup;

typedef struct CcsReferenceLink {
    CcsRecord *source;
    struct CcsReferenceLink *next;
} CcsReferenceLink;

typedef struct CcsSpBattleOwner {
    CcsContainer *container;
    unsigned char _pad_0004[0x11F];
    unsigned char owns_container;
} CcsSpBattleOwner;

typedef struct EtcSkillCcsOwner {
    unsigned char _pad_0000[0x408];
    CcsContainer *shared;
    CcsContainer *stream_common;
    CcsContainer *body_common;
} EtcSkillCcsOwner;

typedef struct EtcContainerOwner {
    unsigned char _pad_0000[0x10];
    CcsContainer *container;
} EtcContainerOwner;

typedef struct EtcDeferredCcsOwner {
    unsigned char _pad_0000[0x18];
    CcsContainer *container;
} EtcDeferredCcsOwner;

typedef struct FighterCcsSide {
    CcsContainer *containers[9];
    char paths[9][30];
    unsigned char _pad_0132[2];
} FighterCcsSide;

typedef struct CcsBattleResourcesManager {
    unsigned char _pad_0000[0xB4C];
    FighterCcsSide sides[2];
} CcsBattleResourcesManager;

typedef struct CcsQueueWorkerTask {
    unsigned char _pad_0000[0x28];
    CcsQueueNode *active;
    int stop;
    int progress_mode;
} CcsQueueWorkerTask;

typedef struct SpSkillBlobHeader {
    char magic[4];
    unsigned int extra_paths_offset;
    unsigned int stream_pairs_offset;
    unsigned int skill_rows_offset;
    unsigned char _pad_0010[0x14];
    unsigned int strings_offset;
    unsigned char _pad_0028[8];
    unsigned int extra_path_count;
    unsigned int stream_pair_count;
    unsigned int skill_count;
} SpSkillBlobHeader;

typedef struct BtlSkillPlayback {
    unsigned char flags;
    unsigned char _pad_0001[0xb];
    void *manager; // +0x0C
    unsigned char _pad_0010[4];
    unsigned char retirement_flags; // +0x14 low two bits
    unsigned char _pad_0015[0x5b];
    unsigned char presentation_active;
    unsigned char _pad_0071[0x6f];
    float saved_camera_vectors[2][4];
    unsigned char _pad_0100[0x10];
    void * vtable;
    unsigned char _pad_0114[0xc];
    RegisteredActorReference registration; // +0x120
    unsigned char _pad_012c[0x2c];
    void * associated_owner;
    unsigned char _pad_015c[0x30];
    void * linked_object;
    unsigned char _pad_0190[0x10];
    unsigned char transfer_flags;
    unsigned char _pad_01a1[0x1f];
    unsigned char transfer_blocked;
    unsigned char _pad_01c1[0x1b];
    int event_value;
    unsigned char _pad_01e0[0x10];
    CcsContainer * container;
    unsigned char _pad_01f4[0xd4];
    int state;
    unsigned char _pad_02cc[0x50];
    Fighter * associated_fighter;
    CcsAnimationPlayer * player;
    unsigned char _pad_0324[0xc];
    float position[4];
    float rotation[4];
    int side;
    unsigned char _pad_0354[4];
    unsigned int playback_event;
    unsigned char _pad_035c[0x2d];
    unsigned char substitute_primary;
    unsigned char _pad_038a[0x142];
    Fighter * second_fighter;
    CcsAnimationPlayer * second_player;
    unsigned char _pad_04d4[0x2C];
    int opposite_side; // +0x500
    unsigned char _pad_0504[0x35];
    unsigned char substitute_second;
    unsigned char _pad_053a[0x32];
    unsigned int resource_id;
    unsigned char _pad_0570[0x20];
    unsigned char camera_event_active;
    unsigned char control_dispatch_active; // +0x591
    unsigned char control_mask_active; // +0x592
    unsigned char _pad_0593;
    int camera_variant;
    unsigned char _pad_0598[0x48];
    float range_value;
    unsigned char _pad_05e4[0x43c];
    unsigned char phase_flags;
    unsigned char _pad_0a21[0x1];
    short alternate_phase_counter;
    unsigned char _pad_0a24[0xb0];
    int phase_counter;
    unsigned char _pad_0ad8[0xc];
    unsigned char countdown_flags;
    unsigned char _pad_0ae5[0x421];
    unsigned char late_sequence_flags; // +0xF06 bit0
    unsigned char _pad_0f07;
    short late_sequence_count; // +0xF08
    unsigned char _pad_0f0a[0xe6];
} BtlSkillPlayback;

typedef struct BtlLinkedPlayer {
    CcsAnimationPlayer player;
    unsigned int flags;
    void * render_context;
    struct BtlLinkedPlayer * next;
    unsigned char _pad_012c[0x4];
} BtlLinkedPlayer;

typedef struct BtlGauge {
    struct BattleTopPanel *parent;
    CcsContainer * container;
    Fighter * fighter;
    void *fill_sprite; void *threshold_sprite; void *marker_sprite; int marker_cell; float marker_scale; unsigned char category; unsigned char _unknown_21[3]; float current; float previous; float reserved_request; float reserved_display;
    float threshold;
    float rate; float pulse_phase; unsigned char reservation_blink; unsigned char blink_count; unsigned char _unknown_42[2];
    CcsAnimationPlayer * fading_player;
    CcsAnimationPlayer * threshold_player;
    CcsAnimationPlayer * state_player;
    unsigned char threshold_active;
    unsigned char fading_active;
    unsigned char state_active;
    unsigned char _pad_0053[0x1];
    float threshold_fade;
    float state_fade;
void *secondary_context; void *view_helper; unsigned char feedback_enabled; unsigned char _unknown_65[3]; float icon_phase;
} BtlGauge;

typedef struct BtlCapturedPose {
    unsigned char _pad_0000[0x8];
    CcsAnimationPlayer * player;
    unsigned int capture_pair[2];
    Fighter * fighter;
    unsigned char _pad_0018[0x8];
    float transform[16];
    float opacity;
    float fade_increment;
    unsigned char _pad_0068[0x8];
    unsigned char flags;
    unsigned char _pad_0071[0xf];
} BtlCapturedPose;

typedef struct BtlCapturedPosePool {
    short count;
    unsigned char _pad_0002[0x2];
    BtlCapturedPose * records;
} BtlCapturedPosePool;

typedef struct BtlTypedResourceRow {
    unsigned char _pad_0000[0x5];
    unsigned char type;
    short binding_code;
    unsigned char _pad_0008[0x4];
} BtlTypedResourceRow;

typedef struct BtlTypedPlayback {
    unsigned char _pad_0000[0x64];
    void * resource;
    void * effect;
    unsigned char _pad_006c[0x8];
    void * selection_record;
    int owner_id;
    unsigned char _pad_007c[0x2];
    short state;
    unsigned char resource_type;
    unsigned char _pad_0081[0x3];
    short delay;
    unsigned char _pad_0086[0x3];
    unsigned char enabled;
    unsigned char _pad_008a[0x172];
    float progress;
    short counter;
    unsigned char _pad_0202[0x76];
    float progress_step;
} BtlTypedPlayback;

typedef struct BtlFrameController {
    unsigned char _pad_0000[0x12];
    short state;
    unsigned short counter;
    unsigned char _pad_0016[0x2];
    unsigned char complete;
    unsigned char _pad_0019[0x2f];
    CcsAnimationPlayer * player;
    unsigned char _pad_004c[0xd0];
    CcsAnimationPlayer * position_player;
} BtlFrameController;

typedef struct BtlAnimationController {
    unsigned char _pad_0000[0x44];
    CcsAnimationDescriptor * descriptor_start;
    unsigned char _pad_0048[0x80];
    int selector;
    int previous_selector;
    unsigned char _pad_00d0[0x4C];
    Fighter *fighter;
    CcsAnimationPlayer * player;
    unsigned char _pad_0124[0x34];
    int counter;
    unsigned char _pad_015c[0x2D];
    unsigned char substitute_primary;
    unsigned char _pad_018a[0x16];
    void *associated_link;
} BtlAnimationController;

typedef struct BgCrashBreak {
    BgBreakObject base;
    unsigned int contact_modes;
    float planar_threshold;
    float vertical_threshold;
} BgCrashBreak;

typedef struct BgBreakDoll {
    BgBreakObject base;
    unsigned char cooldown;
} BgBreakDoll;

typedef struct BgBreakMove {
    BgBreakObject base;
    unsigned char _pad_0190[0xA0];
    int reset_delay;
} BgBreakMove;

typedef struct InteractionPrefix {
    unsigned char _unknown_0000[4];
    char *resource_name;
    unsigned char _unknown_0008[8];
    unsigned int category;
    unsigned int flags;
    unsigned char _unknown_0018[0xC];
    float attack_scalar;
    float knockback_scale;
    unsigned char response_selector;
    signed char guard_selector;
    short repeat_count;
    short update_pause;
    short rejection_count;
    unsigned char _unknown_0034[0x20];
} InteractionPrefix;

typedef struct BtlPoseCapture {
    unsigned char active;
    unsigned char _pad_0001[0x3];
    CcsAnimationDescriptor * saved_descriptor;
    unsigned int saved_frame;
    CcsAnimationDescriptor * replacement_descriptor;
    unsigned char _pad_0010[0x10];
} BtlPoseCapture;

typedef struct BtlCapturedPrimary {
    unsigned char _pad_0000[0x320];
    CcsAnimationPlayer * player;
    unsigned char _pad_0324[0xbec];
    BtlPoseCapture capture;
} BtlCapturedPrimary;

typedef struct BtlRequestedPlayback {
    BtlSkillPlayback base;
    unsigned char _pad_0ff0[0xf0];
    CcsAnimationDescriptor * descriptors[14];
    int requested_state;
    int current_request;
    int pending_request;
    int secondary_request;
    int secondary_count;
    int requested_selector;
    int counter;
    int substate;
    unsigned char _pad_1138[0x51];
    unsigned char direction_changed;
} BtlRequestedPlayback;

typedef struct BtlBytePlayback {
    BtlSkillPlayback base;
    unsigned char selector;
    unsigned char _pad_0ff1[0x3];
    CcsAnimationDescriptor * descriptor_ff4;
    CcsAnimationDescriptor * descriptor_ff8;
    CcsAnimationDescriptor * descriptor_ffc;
    CcsAnimationDescriptor * descriptor_1000;
} BtlBytePlayback;

typedef struct BtlStoredBytePlayback {
    BtlSkillPlayback base;
    unsigned char _pad_0ff0[0x18];
    CcsAnimationDescriptor * descriptors[5];
    unsigned char _pad_101c[0x8d7];
    unsigned char selector;
} BtlStoredBytePlayback;

typedef struct BtlCounterPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[2];
    unsigned short counter;
    short state;
} BtlCounterPlayback;

typedef struct BtlSknPlayback {
    BtlCounterPlayback base;
    void * registration;
} BtlSknPlayback;

typedef struct BtlZbzPlayback {
    BtlCounterPlayback base;
    unsigned char finished;
} BtlZbzPlayback;

typedef struct BtlSkmPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptor;
    unsigned short counter;
    short state;
    void * registration;
} BtlSkmPlayback;

typedef struct BtlGavPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[3];
    unsigned short counter;
    short state;
} BtlGavPlayback;

typedef struct BtlGarPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[2];
    unsigned char _pad_0ff8[0xc];
    signed char counter;
    unsigned char _pad_1005[0x1];
    short state;
} BtlGarPlayback;

typedef struct BtlTovPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[8];
    unsigned short counter;
    unsigned short saved_counter;
    short limit;
    unsigned char _pad_1016[0x2a];
    short state;
    unsigned char _pad_1042[0xae];
    unsigned char variant;
    unsigned char secondary_variant;
} BtlTovPlayback;

typedef struct BtlAsmPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[4];
    unsigned char _pad_1000[0x10];
    unsigned short counter;
    unsigned short saved_counter;
    short limit;
    unsigned char _pad_1016[0x7a];
    short state;
} BtlAsmPlayback;

typedef struct BtlKibPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[7];
    unsigned short counter;
    short state;
    unsigned char _pad_1010[0x1b0];
    CcsAnimationPlayer embedded_player;
    unsigned char _pad_12e0[0x20];
    unsigned char effect_active;
    unsigned char _pad_1301[0x5b];
    unsigned char effect_flags;
} BtlKibPlayback;

typedef struct BtlGuwPlayback {
    BtlSkillPlayback base;
    unsigned char _pad_0ff0[0xa0];
    void * transform_resource;
    void * other_object;
    int selector;
    int counter;
    int substate;
    unsigned char _pad_10a4[0x2c];
    float transform_value;
    unsigned char _pad_10d4[0xc];
    CcsAnimationPlayer embedded_player;
    unsigned char _pad_1200[0x1];
    unsigned char enabled;
} BtlGuwPlayback;

typedef struct BtlFrogPlayback {
    unsigned char _pad_0000[0x90];
    int owner_id;
    unsigned char _pad_0094[0x820];
    CcsAnimationDescriptor * initial_descriptor;
    CcsAnimationDescriptor * transition_descriptor;
    unsigned char _pad_08bc[0x186];
    unsigned char transition_ready;
    unsigned char _pad_0a43[0x24d];
    void * wrapped_player;
    unsigned char _pad_0c94[0xb];
    unsigned char complete;
    unsigned char _pad_0ca0[0x64];
    int state;
    int state_counter;
    int counter;
} BtlFrogPlayback;

typedef struct BtlAssociatedPlayback {
    unsigned char flags;
    unsigned char _pad_0001[0xb33];
    CcsAnimationPlayer * player;
    void * container_effect;
    void * local_resource;
    unsigned char _pad_0b40[0x8];
    unsigned int complete;
    unsigned char _pad_0b4c[0x30];
    float opacity;
} BtlAssociatedPlayback;

typedef struct BtlDirectionalPlayback {
    unsigned char _pad_0000[0x78];
    float settled_value;
    unsigned char _pad_007c[0x50];
    void * decorations[5];
    unsigned char _pad_00e0[0x7c];
    void * decoration;
    unsigned char left_active;
    unsigned char right_active;
    unsigned char _pad_0162[0x2];
    CcsAnimationPlayer * left_player;
    CcsAnimationPlayer * right_player;
} BtlDirectionalPlayback;

typedef struct BtlChyPlayback {
    BtlSkillPlayback base;
    unsigned char _pad_0ff0[0x120];
    CcsAnimationPlayer * supplementary_player;
} BtlChyPlayback;

typedef struct BtlStoppedCounterPlayback {
    unsigned char _pad_0000[0x8];
    int counter;
    unsigned char _pad_000c[0x34];
    CcsAnimationPlayer * player;
} BtlStoppedCounterPlayback;

typedef struct BtlResetPlayback {
    unsigned char _pad_0000[0x24];
    CcsAnimationPlayer * player;
} BtlResetPlayback;

typedef struct BtlTyvObject {
    unsigned char flags;
    unsigned char _pad_0001[0xa1f];
    unsigned char phase_flags;
    unsigned char _pad_0a21[0xc3];
    unsigned char countdown_flags;
    unsigned char _pad_0ae5[0xab];
    CcsAnimationPlayer * player;
    void * composition;
    unsigned char _pad_0b98[0x3c];
    float opacity;
    unsigned char _pad_0bd8[0x24];
    signed char state;
    unsigned char _pad_0bfd[0x1];
    unsigned short counter;
    unsigned char _pad_0c00[0x20];
} BtlTyvObject;

typedef struct BtlTyvPlayback {
    BtlCounterPlayback base;
    unsigned char fade_requested;
    unsigned char _pad_0ffd[0x3];
    int registration_slot;
    int registration_id;
    int registration_aux_id;
} BtlTyvPlayback;

typedef struct BtlSawarabiRecord {
    CcsAnimationPlayer player;
    unsigned char _pad_0120[0x10];
    short activation_delay;
    short return_delay;
    short state;
    unsigned char _pad_0136[0x20a];
} BtlSawarabiRecord;

typedef struct BtlSawarabiPlayback {
    unsigned char _pad_0000[0xaf0];
    BtlSawarabiRecord records[20];
    CcsAnimationDescriptor * initial_descriptor;
    CcsAnimationDescriptor * return_descriptor;
} BtlSawarabiPlayback;

typedef struct BtlWaterDragonPlayback {
    unsigned char _pad_0000[0xd60];
    CcsAnimationPlayer player;
    unsigned char enabled;
    unsigned char _pad_0e81[0x5f];
    void * attachment;
    unsigned char _pad_0ee4[0x10];
    unsigned int complete;
    void * render_context;
    unsigned char _pad_0efc[0x4];
    short state;
} BtlWaterDragonPlayback;

typedef struct BtlAnbPlayback {
    BtlSkillPlayback base;
    CcsAnimationDescriptor * descriptors[17];
    unsigned char _pad_1034[0x4];
    unsigned short counter;
    short state;
    unsigned char _pad_103c[0x14];
    float height;
    unsigned char _pad_1054[0x94];
    short previous_state;
    unsigned char transition_armed;
    unsigned char _pad_10eb[0xa5];
    unsigned char frame_variant;
    unsigned char next_frame_variant;
    unsigned char _pad_1192[0x1e];
    CcsAnimationPlayer embedded_player;
    unsigned char enabled;
    unsigned char _pad_12d1[0x73];
    unsigned int complete;
    void * render_context;
    unsigned char _pad_134c[0x4];
    signed char range_index;
} BtlAnbPlayback;

typedef struct BtlForRecord {
    CcsAnimationPlayer player;
    unsigned char _pad_0120[0x46];
    unsigned char enabled;
    unsigned char _pad_0167[0x19];
    unsigned short next_step;
    unsigned char _pad_0182[0xe];
} BtlForRecord;

typedef struct BtlForPlayback {
    BtlSkillPlayback base;
    unsigned char selector;
    unsigned char _pad_0ff1[1];
    unsigned short damage_updates; // +0xFF2
    float cumulative_damage; // +0xFF4
    float secondary_damage; // +0xFF8 setup snapshot
    float damage_step; // +0xFFC
    unsigned char _pad_1000[4];
    CcsAnimationDescriptor * first_descriptor;
    CcsAnimationDescriptor * second_descriptor;
    unsigned char _pad_100c[0x194];
    BtlForRecord first;
    BtlForRecord second;
} BtlForPlayback;

typedef struct BtlTndRecord {
    CcsAnimationPlayer player;
    unsigned char _pad_0120[0x10];
    unsigned int local_word;
    unsigned char _pad_0134[0xc];
    unsigned char stop_on_completion;
    unsigned char completion_latched;
    unsigned char _pad_0142[0xe];
} BtlTndRecord;

typedef struct BtlTndGroup {
    unsigned char active;
    unsigned char draw_suppressed;
    unsigned char _pad_0002[0x3e];
    CcsAnimationPlayer main_player;
    BtlTndRecord children[3];
} BtlTndGroup;

typedef struct BtlTndPlayback {
    BtlSkillPlayback base;
    unsigned char _pad_0ff0[0x34];
    CcsAnimationDescriptor * child_descriptor;
    unsigned char _pad_1028[0x10];
    CcsAnimationDescriptor * main_descriptor;
    unsigned char _pad_103c[0x204];
    BtlTndGroup group;
} BtlTndPlayback;

typedef struct BtlWallPlayback {
    unsigned char flags;
    unsigned char _pad_0001[0xa1f];
    unsigned char phase_flags;
    unsigned char _pad_0a21[0x1];
    short alternate_phase_counter;
    unsigned char _pad_0a24[0xb0];
    int phase_counter;
    unsigned char _pad_0ad8[0xc];
    unsigned char countdown_flags;
    unsigned char _pad_0ae5[0xb];
    CcsAnimationPlayer * player;
    unsigned int complete;
    void * top_object;
    unsigned char _pad_0afc[0xae];
    unsigned char pose_selector;
} BtlWallPlayback;

typedef struct BtlGatePlayback {
    unsigned char flags;
    unsigned char _pad_0001[0xa1f];
    unsigned char phase_flags;
    unsigned char _pad_0a21[0x1];
    short alternate_phase_counter;
    unsigned char _pad_0a24[0xb0];
    int phase_counter;
    unsigned char _pad_0ad8[0xc];
    unsigned char countdown_flags;
    unsigned char _pad_0ae5[0x2db];
    CcsAnimationPlayer * player;
    void * top_object;
    unsigned char _pad_0dc8[0x28];
    unsigned int complete;
} BtlGatePlayback;

typedef struct BtlSharedPoseInstance {
    float opacity;
    unsigned char _pad_0004[0xdc];
} BtlSharedPoseInstance;

typedef struct BtlSharedPosePlayback {
    unsigned char _pad_0000[0x1c72];
    short frame;
    unsigned char _pad_1c74[0x2c];
    CcsAnimationPlayer shared_player;
    CcsAnimationPlayer first_player;
    CcsAnimationPlayer ordinary_first;
    unsigned char _pad_2000[0x10];
    CcsAnimationPlayer ordinary_second;
    unsigned char _pad_2130[0x4c];
    unsigned char draw_suppressed;
} BtlSharedPosePlayback;

typedef struct BtlDescriptorArray {
    unsigned char _pad_0000[0x4];
    CcsAnimationPlayer * players;
    float * offsets;
    signed char count;
    unsigned char _pad_000d[0x3];
    CcsAnimationDescriptor * descriptors[5];
} BtlDescriptorArray;

typedef struct BtlDescriptorArrayPlayback {
    BtlSkillPlayback base;
    int counter;
    int limit;
    unsigned char _pad_0ff8[0x7c];
    BtlDescriptorArray array;
} BtlDescriptorArrayPlayback;

typedef struct BtlLinkedPlayback {
    BtlSkillPlayback base;
    unsigned char _pad_0ff0[0xc4];
    BtlLinkedPlayer * head;
    unsigned char _pad_10b8[0x58];
    BtlLinkedPlayer * first_node;
} BtlLinkedPlayback;

typedef struct WrappedScenePlayback {
    struct WrappedScenePlaybackVtableView *vtable;
    int index; // +0x4
    unsigned int generation;
    unsigned char _pad_000C[0x10];
    int support_mode;
    unsigned char _pad_0020[4];
    unsigned char removal_flags; // +0x24 low bit requests release/unlink
    unsigned char _pad_0025[3];
    int signed_offset; // effect constructors store the negated low-three-bit selector
    unsigned char _pad_002c[8];
    float support_scalar;
    unsigned char update_enabled; // +0x38
    unsigned char draw_enabled;
    unsigned char _pad_003a[0x8a];
    unsigned int bookkeeping_mask; // +0xC4
    unsigned char fade_phase; // +0xC8 low two bits
    unsigned char _pad_00c9;
    short fade_in_count; // +0xCA
    short fade_hold_count; // +0xCC
    short fade_out_count; // +0xCE
    unsigned char _pad_00d0[0xcc];
    int kind;
    void * resource;
    unsigned char _pad_01a4[4];
    void *composition; // +0x1A8
    unsigned char looping; // +0x1AC
    unsigned char retirement_enabled; // +0x1AD
    unsigned char retirement_requested;
    unsigned char complete;
    unsigned char owns_resource;
    unsigned char occupied;
    unsigned char _pad_01B2[2];
    struct WrappedScenePlayback *previous; // +0x1B4
    struct WrappedScenePlayback *next; // +0x1B8
    int retirement_countdown;
    unsigned char _pad_01C0[0x20];
    unsigned short playback_step;
    unsigned char _pad_01E2[6];
    unsigned int selected_index; // +0x1E8 kind-3 selection
    unsigned char playback_gate; // +0x1EC
    unsigned char _pad_01ED[3];
    float rotation; // +0x1F0
    float scale_x; // +0x1F4
    float scale_y; // +0x1F8
    float scale_z; // +0x1FC
    float fade_lower; // +0x200
    float fade_upper; // +0x204
    short delay;
} WrappedScenePlayback;

typedef struct CcsReferenceRuntime {
    unsigned char _pad_0000[4];
    CcsRecord *source_record;
} CcsReferenceRuntime;

typedef struct BtlPendingDescriptor {
    unsigned char _pad_0000[0x4c];
    CcsAnimationDescriptor * descriptor;
    unsigned char pending;
    unsigned char _pad_0051[0x3];
    unsigned int request_value;
    unsigned int request_aux_value;
} BtlPendingDescriptor;

typedef struct BtlDescriptorTransferRow {
    unsigned char _pad_0000[0x4];
    unsigned char transfer_enabled;
    unsigned char transfer_kind;
    unsigned char _pad_0006[0x2];
} BtlDescriptorTransferRow;

typedef struct BtlDescriptorCallbackPlayback {
    unsigned char _pad_0000[0x320];
    CcsAnimationPlayer * player;
    unsigned char _pad_0324[0x34];
    unsigned int playback_event;
    unsigned char _pad_035c[0xcbc];
    float descriptor_choice;
    unsigned char _pad_101c[0x8];
    CcsAnimationDescriptor * positive_descriptor;
    CcsAnimationDescriptor * nonpositive_descriptor;
    unsigned char callback_ready;
} BtlDescriptorCallbackPlayback;

typedef struct BtlAssociatedSelectorPlayback {
    unsigned char _pad_0000[0x4cc];
    Fighter * fighter;
    CcsAnimationPlayer * player;
    unsigned char _pad_04d4[0x65];
    unsigned char substitute_primary;
    unsigned char _pad_053a[0xaca];
    int state;
    unsigned char _pad_1008[0x4];
    int counter;
    unsigned char enabled;
    unsigned char _pad_1011[0x6f];
    void * object;
} BtlAssociatedSelectorPlayback;

typedef struct ProjectileChase {
    Projectile base;
    unsigned char _pad_0290[0x20];
    float clock;
    unsigned char _pad_02b4[4];
    float turn_scalar;
    short active_service_id_a;
    short retiring_service_id;
    short active_service_id_b;
    unsigned char flags;
    unsigned char _pad_02c3[5];
    float steering_deadline;
    unsigned char steering_enabled;
    unsigned char _pad_02cd;
    unsigned char stored_launch_target;
    unsigned char _pad_02cf;
    float launch_delay;
} ProjectileChase;

typedef struct ProjectileKibakufuda {
    Projectile base;
    unsigned char _pad_0290[0x10];
    unsigned char position_service_enabled;
    unsigned char attachment;
    unsigned char _pad_02a2[2];
    float angle;
    float angular_rate;
    unsigned char _pad_02ac[4];
    float acceleration_increment;
    float position_service_argument;
    unsigned char _pad_02b8[0x60];
    int registration_count;
} ProjectileKibakufuda;

typedef struct ProjectileFloatLauncher {
    Projectile base;
    unsigned char phase;
    unsigned char _pad_0291[3];
    float angle;
    float horizontal_speed;
    float speed_increment;
    float speed_limit;
    float direction;
    float startup_deadline;
    float emission_deadline;
    void *owned_service;
    unsigned char owned_service_enabled;
} ProjectileFloatLauncher;

typedef struct ProjectileTewSkillAnki {
    Projectile base;
    short context_threshold;
    short context_span;
} ProjectileTewSkillAnki;

typedef struct ProjectileInkOwned {
    Projectile base;
    void *owned_service;
} ProjectileInkOwned;

typedef struct ProjectileDelayedLauncher {
    Projectile base;
    int child_config;
    int remaining;
    int interval;
} ProjectileDelayedLauncher;

typedef struct ProjectileCountedLauncher {
    Projectile base;
    unsigned char _pad_0290[8];
    int remaining;
} ProjectileCountedLauncher;

typedef struct ProjectileDdrLauncher {
    Projectile base;
    unsigned char _pad_0290[4];
    int remaining;
} ProjectileDdrLauncher;

typedef struct ProjectileHakLauncher {
    Projectile base;
    int emission_count;
} ProjectileHakLauncher;

typedef struct ProjectileSyncHand {
    Projectile base;
    short emission_index;
} ProjectileSyncHand;

typedef struct ProjectileMakibishi {
    Projectile base;
    unsigned char phase;
    unsigned char _pad_0291[3];
    float context_scalar;
    unsigned int context_word;
    float gravity_decrement;
} ProjectileMakibishi;

typedef struct ProjectileExplode {
    Projectile base;
    short startup_countdown;
    short active_countdown;
    unsigned char _pad_0294[4];
    unsigned int post_spawn_word;
} ProjectileExplode;

typedef struct ProjectileIronMetadata {
    unsigned char _pad_0000[0x120];
    unsigned int word120;
    unsigned int lineage_word;
    unsigned int marker;
} ProjectileIronMetadata;

typedef struct ProjectileResidentService {
    unsigned char _pad_0000[0x1c];
    short submission_halfword;
    unsigned char _pad_001e[0xa];
    float scalar;
    unsigned char _pad_002c[0x14];
    float transform[16];
    unsigned char _pad_0080[0xd];
    unsigned char transform_enabled;
    unsigned char _pad_008e[0xa];
    void **resources;
    unsigned short resource_count;
} ProjectileResidentService;

typedef struct ProjectileSkillService {
    unsigned char _pad_0000[0x98];
    unsigned int event_value;
    unsigned char _pad_009c[0x4c];
    float context_scalar;
    unsigned int service_word;
} ProjectileSkillService;

typedef struct CoordinatorAuxiliaryB0 {
    unsigned char _pad_0000[0x40];
    void *owned_storage; // released and nulled before the auxiliary is freed
    unsigned char _pad_0044[0x6C];
} CoordinatorAuxiliaryB0;

typedef struct BattleTopPanel {
    float draw_x; float draw_y; float scale; unsigned char side; unsigned char _unknown_0d[3]; int character_id; Fighter *fighter; void *primary_context; void *secondary_context; struct BattleHudFrame *frame; struct BattleHudHp *hp; BtlGauge *chakra; struct BattleHudName *name; float base_x; float base_y; float offset_x; float offset_y; unsigned char _unknown_40[4]; float slide_velocity;
    int transition_selector; // 0 hide, 1 show, 2 shake, 3 idle
    int hide_state; int show_state;
    unsigned char child_draw_suppressed; // 1 skips child draw; re-entry waits for nonzero
    unsigned char _unknown_55[3]; int shake_state; short shake_count; signed char shake_duration; signed char shake_samples; float shake_amplitude; short shake_index; unsigned char _unknown_66[2];
} BattleTopPanel;

typedef struct NativeCombo {
    Fighter *fighter;
    void *combo_display; // borrowed presentation child
    void *other_displays[2]; // borrowed root presentation children
    TimelineBlock reset_window;
    short current;
    short largest_completed;
    int notification_phase;
} NativeCombo;

typedef struct EffectDisplayDescriptor { unsigned int style; float upper; float lower_delta; float upper_delta; } EffectDisplayDescriptor;

typedef struct ItemMetadata { unsigned char kind; unsigned char _pad_01; unsigned short flags; float amount; short direct_effect; unsigned char _pad_0a[2]; } ItemMetadata;

typedef struct ItemStatusLane { int effect; int interleaved; } ItemStatusLane;

typedef struct ItemStatusRow { unsigned char item; unsigned char _pad_01[3]; int requested; ItemStatusLane lanes[4]; } ItemStatusRow;

typedef struct EffectFactoryRegistration { int effect; void *factory; } EffectFactoryRegistration;

typedef struct EffectNotificationMap { int effect; int code; } EffectNotificationMap;

typedef struct EffectAuxSelector { int effect; signed char selector; unsigned char _pad_05[3]; } EffectAuxSelector;

typedef struct EffectAuxVisual { unsigned char _pad_00[0x60]; void *composition; void *primary; void *secondary; short countdown; short effect; short side; unsigned char _pad_72[0xe]; } EffectAuxVisual;

typedef struct Fukidasi { void *vtable; float display_x; float display_y; unsigned char code; unsigned char state; unsigned char _pad_0e[6]; int callback_argument; int side; unsigned char _pad_1c[4]; float position[4]; float opacity; float bubble_scale; int rank_x; int rank_y; struct Fukidasi *next; } Fukidasi;

typedef struct FukidasiList { Fukidasi *head; int side; } FukidasiList;

typedef struct FukidasiNumeric { Fukidasi base; unsigned char _pad_44[0xc]; int value; float digit_scale; } FukidasiNumeric;

typedef struct Effect4aNode { AwakeningEffectNode base; int response_state; void *primary; void *secondary; unsigned char _pad_cc[4]; float phase_a; float phase_b; float phase_c; unsigned char _unknown_dc[4]; } Effect4aNode;

typedef struct ItemEffectController { unsigned char _pad_00[0x44]; Fighter *fighter; int blocked; unsigned char _pad_4c[0x34]; int requested_effect; } ItemEffectController;

typedef struct SkillSpawnEvent {
    unsigned char _unknown_0000[4];
    unsigned int event_word; // 0x8003 selects this bridge's command handling
    unsigned int authored_selector; // unsigned 0x100..0x1C4 maps to factory 0..0xC4
} SkillSpawnEvent;

typedef struct SkillEventContext {
    Fighter *fighter; // borrowed callback owner
    unsigned char _unknown_0004[4]; // dispatcher initializes this word to zero
} SkillEventContext;

typedef struct ToneShadeRandomAnimator { void *vtable; unsigned short counter; unsigned short period; } ToneShadeRandomAnimator;

typedef struct ToneShadeRandomDestination { unsigned char _unknown_00[4]; float coefficient; unsigned char _unknown_08[0x2c]; float random_component0; float random_component1; } ToneShadeRandomDestination;

typedef struct RngEngineRoot { unsigned char _unknown_0000[4]; unsigned int profile_horizontal_blanks; unsigned char _unknown_0008[0x18C]; unsigned int update_counter; } RngEngineRoot;

typedef struct RngScaleModel { unsigned char _unknown_0000[0xe4]; float z_extent; float x_extent; unsigned char _unknown_00ec[0x204]; float scale; } RngScaleModel;

typedef struct RngPositionTarget { unsigned char _unknown_0000[0x11c]; RngScaleModel *model; unsigned char _unknown_0120[0x10]; float position[4]; unsigned char _unknown_0140[0x49]; unsigned char model_valid; } RngPositionTarget;

typedef struct RngPositionReceiver { unsigned char _unknown_0000[0x4cc]; RngScaleModel *model; unsigned char _unknown_04d0[0x69]; unsigned char model_valid; unsigned char _unknown_053a[0xba2]; int state; unsigned char _unknown_10e0[0x6c0]; short phase; unsigned char _unknown_17a2[0x1a]; int count_limit; unsigned char _unknown_17c0[0x32]; short invocation_count; unsigned char _unknown_17f4[0xc]; unsigned int visual_blocked; } RngPositionReceiver;

typedef struct RngPairRecord { unsigned char _unknown_00[0x44]; float remapped_value; unsigned char _unknown_48[0xb8]; } RngPairRecord;

typedef struct RngPairOwner { unsigned char _unknown_0000[0xaf0]; RngPairRecord *records; short record_count; unsigned char _unknown_0af6[2]; } RngPairOwner;

typedef struct RngShuffledIds { short last_index; short current_index; unsigned char _unknown_04[4]; short ids[94]; } RngShuffledIds;

typedef struct RngMaskedEffectOwner { unsigned char _unknown_0000[0x1008]; unsigned int retained_selector; } RngMaskedEffectOwner;

typedef struct SaveTimestamp { unsigned char reserved; unsigned char seconds; unsigned char minutes; unsigned char hours; unsigned char day; unsigned char month; unsigned short year; } SaveTimestamp;

typedef struct SaveDescriptor { unsigned char occupied; signed char classification; unsigned short checksum; int play_time; SaveTimestamp modified; } SaveDescriptor;

typedef struct AbilityBits { unsigned int words[6]; } AbilityBits;

typedef struct SurvivalRankingEntry { int character_id; int metric; } SurvivalRankingEntry;

typedef struct SaveSecondaryBlock {
 unsigned char byte_bank0[850];
 unsigned short halfword_bank[850];
 unsigned char byte_bank1[850];
 unsigned int word_bank0[70];
 unsigned int word_bank1[297];
 unsigned char byte_bank2[246];
 unsigned char _gap_13fa[2];
 unsigned char opaque_13fc[0x1C];
 unsigned char opaque_1418[0x180];
} SaveSecondaryBlock;

typedef struct SaveProfile {
 unsigned short discriminator;
 unsigned short checksum;
 int play_time;
 short display_x;
 short display_y;
 unsigned short volume;
 unsigned short audio_mode;
 unsigned char vibration_mask;
 unsigned char _gap_0011;
 unsigned short bindings[2][8];
 unsigned char _gap_0032[2];
 int ryo;
 AbilityBits abilities[94];
 unsigned char character_status[94];
 unsigned char _gap_0966[2];
 unsigned int secondary_availability[2];
 unsigned char small_availability[32];
 unsigned char figures[93];
 unsigned char music[41];
 unsigned char voices[155];
 unsigned char skills[168];
 unsigned char movies[7];
 unsigned char dioramas[12];
 SurvivalRankingEntry survival_times[25][3];
 SurvivalRankingEntry survival_wins[2][3];
 unsigned int gate_bits;
 unsigned int scalar;
 SaveSecondaryBlock secondary;
 unsigned char opaque_tail[0x6C];
} SaveProfile;

typedef struct SaveWorker {
 SaveDescriptor descriptors[4];
 int port;
 int selected_slot;
 int operation;
 int status;
 int result_class;
 int mode;
 int preflight_result;
 struct TaskCleanupRecord *task;
} SaveWorker;

typedef struct CardDirectoryEntry {
 SaveTimestamp created;
 SaveTimestamp modified;
 unsigned int file_size;
 unsigned char _unknown_0014[0xC];
 char filename[0x20];
} CardDirectoryEntry;

typedef struct CardInfo { int unknown0; int type; int free_blocks; int formatted; int result; } CardInfo;

typedef struct SaveCardContext {
 char directory[0x44];
 int file_handle;
 CardIconSystem icon_sys;
 CardInfo card_info[2];
 int expected_blocks;
} SaveCardContext;

typedef struct SaveDialogUi {
 unsigned char visible;
 unsigned char text_enabled;
 unsigned char choice_enabled;
 unsigned char slots_visible; unsigned char slots_enabled; unsigned char _unknown_0005[3]; int mode; int port; int selected_slot;
 int choice;
 float selected_x_offset; UiPanel *lower_panel; UiPanel *upper_panel; unsigned char _unknown_0024[0xc];
 SaveDescriptor *slots[3];
 unsigned char _unknown_003c[4];
 char *text;
} SaveDialogUi;

typedef struct SaveDialogController {
 unsigned char _unknown_0000[8]; int state; unsigned char _unknown_000c[0xc]; unsigned char outer_transition_enabled; unsigned char _unknown_0019[3]; int outer_transition_handle; int outer_transition_resource;
 SaveDialogUi *ui;
} SaveDialogController;

typedef struct CardRpcDirectoryRequest { int port; int slot; int mode; int maximum_rows; CardDirectoryEntry *destination; char pattern[1]; } CardRpcDirectoryRequest;

typedef struct ChakraCharacterRecord {
    unsigned char _unknown_0000[0xd8];
    float chakra_recovery;
} ChakraCharacterRecord;

typedef struct FighterResourceConfiguration {
    ChakraCharacterRecord *character_record;
    unsigned char _unknown_0004[0xD];
    unsigned char selected_color; // +0x11, low two bits copied to Fighter.control_flags bits1..2
    unsigned char _unknown_0012[0xA];
    float initial_hp;
    float initial_chakra;
} FighterResourceConfiguration;

typedef struct ChakraControlState {
    unsigned int reset_words[2];
    OverrideRequest update_requests[2];
    OverrideRequest render_requests[2];
    OverrideRequest special_requests[2];
    unsigned char enabled;
    unsigned char _unknown_0039[3];
    int active;
} ChakraControlState;

typedef struct AbsGuardOwner {
    unsigned char flags;
    unsigned char _unknown_0001[0x30f];
    unsigned int visual_mode;
} AbsGuardOwner;

typedef struct AbsGuardEffect {
    void *vtable;
    unsigned char _unknown_0004[0x3c];
    float position[4];
    unsigned char _unknown_0050[0x50];
    void *visual;
    unsigned char _unknown_00a4[4];
    AbsGuardOwner *owner;
} AbsGuardEffect;

typedef struct ChakraAuthoredController {
    unsigned char _unknown_0000[0x31c];
    Fighter *fighter;
    unsigned char _unknown_0320[0x2c8];
    float requested_chakra;
} ChakraAuthoredController;

typedef struct ChakraAmountController {
    unsigned char _unknown_0000[0x31c];
    Fighter *fighter;
    unsigned char _unknown_0320[0xdb8];
    float requested_chakra;
} ChakraAmountController;

typedef struct ChakraGuardController {
    unsigned char _unknown_0000[0x9d4];
    Fighter *fighter;
    int fighter_unavailable;
} ChakraGuardController;

typedef struct SupportIndexedHandle { int index; unsigned int generation; void *record; } SupportIndexedHandle;

typedef struct SupportScriptWrapper { unsigned char _unknown_0000[0xC]; unsigned int *commands; } SupportScriptWrapper;

typedef struct SupportNotificationRing { unsigned int identifiers[4]; unsigned int next; } SupportNotificationRing;

typedef struct SupportCandidateRow { int primary; unsigned char candidates[3]; unsigned char padding; } SupportCandidateRow;

typedef struct SupportCodeRow { unsigned char support; unsigned char primary; unsigned char code; } SupportCodeRow;

typedef struct SupportRechargeRow { unsigned char support; unsigned char primary; unsigned char recharge_class; } SupportRechargeRow;

typedef struct SupportPresentationHeader { int count; void *head; unsigned char _unknown_0008[0x18]; } SupportPresentationHeader;

typedef struct SupportPresentationNode { void *definition; void *player; unsigned char _unknown_0008[0x1C]; void *sample_buffer; unsigned char _unknown_0028[0x90]; unsigned char first_record[0x14]; unsigned char second_record[0x14]; struct SupportPresentationNode *next; unsigned char _unknown_00E4[0xC]; } SupportPresentationNode;

typedef struct PracticeSettingsPack { unsigned char flags; unsigned char health; unsigned char ultimate; unsigned char time; unsigned char items; unsigned char handicap; unsigned char status; unsigned char strength; unsigned char attack; unsigned char guard; unsigned char move; unsigned char linked_attack; } PracticeSettingsPack;

typedef struct PracticeSettings { unsigned char initialized; unsigned char _pad_01[3]; void *archive; void *backing[4]; void *panels[4]; void *sprites[3]; void *help; int phase; int selection; int repeat_countdown; float row_offset; unsigned char backdrop; unsigned char _pad_49[3]; float phase_a; float phase_b; short alpha; short reveal_delay; float phase_c; short draw_transform; unsigned char _pad_5e[2]; unsigned int pressed; unsigned int held; unsigned int directional; int values[17]; int upper_start; int lower_start; } PracticeSettings;

typedef struct BattleSettings { CcsContainer *archive; unsigned char _unknown_04[4]; void *legend_sprite; void *button_sprite; void *prompt_sprite; void *font_context; void *help; void *render_context; CcsAnimationPlayer *backing_player; CcsAnimationPlayer *scene_player; CcsAnimationPlayer *row_cursor; CcsAnimationPlayer *handicap_cursor; int values[6]; short selection; short repeat_countdown; float phase_a; float phase_b; short alpha; short reveal_delay; short phase; unsigned char _unknown_5a[2]; unsigned int held; unsigned int pressed; unsigned int directional; } BattleSettings;

typedef struct SettingsParent { int state; int availability[2]; unsigned char _unknown_0c[0x24]; void *selectors[2]; BattleSettings *battle; PracticeSettings *practice; unsigned char _unknown_40[8]; int transition_resource; int result; int delay; } SettingsParent;

typedef struct SettingsSelector { int phase; unsigned char _unknown_04[0x18]; int input_source; unsigned int pressed; unsigned int secondary; unsigned int held; } SettingsSelector;

typedef struct PracticeWrapper { int input_source; int context; void *vtable; PracticeSettings *child; } PracticeWrapper;

typedef struct StartMenuHost { int state; int input_source; int secondary_state1; int context; int selection; int repeat_countdown; int command_count; int commands[7]; PracticeWrapper *module; void *render_context; unsigned char _unknown_40[4]; void *transition; unsigned char _unknown_48[0x1c]; float transition_x; unsigned char _unknown_68[4]; float transition_scale; float transition_step; unsigned char _unknown_74[0x10]; float panel_center_y; void *panel_display; void *owned_handle; unsigned char _unknown_90[0x30]; int effect_handle; int asynchronous_result; void *asynchronous_owner; } StartMenuHost;

typedef struct PracticePreparationOwner { int state; int input_source; int reinitialize; int context; int choice_count; int choices[24]; int choice_index; float carousel_displacement; unsigned char _unknown_7c[4]; unsigned int fade_handle; int result; int result_countdown; int random_ticks; int update_count; float random_phase; unsigned char _unknown_98[4]; unsigned int input_primary; unsigned int input_secondary; unsigned int input_directional; SettingsParent *settings; void *mapsel_container; void *scene_draw_list; void *sprite_draw_list; void *legend_sprite; void *name_sprite; void *counter_font; void *digit_sprite; void *camera_animation; void *selection_animation; void *ring_animation1; void *ring_animation2; void *arm_animation; void *tv_animation; void *titlebox; void *carousel; void *owned_objects[24]; CcsModelInstance *big_preview_model; CcsTextureChunk *preview_textures[4]; void *arrow_animation; unsigned char arrow_trigger[2]; unsigned char _unknown_162[2]; void *extra_objects[2]; } PracticePreparationOwner;

typedef struct PracticeDriver { int state; unsigned char _unknown_04[0x10]; int variant; unsigned char _unknown_18[0xc]; float hp1_snapshot; float chakra1_snapshot; float hp2_snapshot; float chakra2_snapshot; void *child34; PracticePreparationOwner *preparation; struct BtlRecordOwner *record_owner; } PracticeDriver;

typedef struct PracticeSessionPhase { unsigned char _unknown_00[0xa]; short phase; } PracticeSessionPhase;

typedef struct BattleRuleMode { unsigned char _unknown_000[0x105]; unsigned char ultimate_mode; } BattleRuleMode;

typedef struct RenderPoolAllocation { struct RenderPoolAllocation *next; void *owner_list; unsigned int total_bytes; unsigned char _unknown_0c[4]; } RenderPoolAllocation;

typedef struct PracticeDamageDisplay { unsigned char _unknown_00[0xc]; short side; unsigned char _unknown_0e[0x3e]; unsigned char flags; } PracticeDamageDisplay;

typedef struct CommandsHudState { unsigned char _unknown_00[3]; unsigned char phase; } CommandsHudState;

typedef struct SupportAttackSample { unsigned char _unknown_0000[0x18]; float radius; unsigned char _unknown_001C[4]; float point[4]; unsigned char _unknown_0030[0x20]; } SupportAttackSample;

typedef struct SupportCollection { unsigned char _unknown_0000[8]; int result_count; unsigned char _unknown_000C[0x1C]; } SupportCollection;

typedef struct SupportIndexedObject { SupportObject base; SupportIndexedHandle effect; unsigned char _unknown_051C[4]; float retained_origin[4]; } SupportIndexedObject;

typedef struct SupportListObject { SupportObject base; SupportPresentationHeader *presentation; } SupportListObject;

typedef struct SupportIndexedPoolOwner { unsigned char _unknown_0000[0x41C]; WrappedScenePlayback *records; unsigned char _unknown_0420[4]; int capacity; } SupportIndexedPoolOwner;

typedef struct PadPacket {
 unsigned char status;
 unsigned char id;
 unsigned char buttons[2]; // active-low, high byte first
 unsigned char right_x, right_y, left_x, left_y;
 unsigned char pressure[12]; // Right Left Up Down Triangle Circle Cross Square L1 R1 L2 R2
 unsigned char reserved[12];
} PadPacket;

typedef struct VibrationEntry {
 unsigned short remaining; // nominal 60Hz display ticks
 unsigned char flags; // bit0 dirty, bit1 small motor; upper bits have no proven use
 unsigned char large_intensity;
} VibrationEntry;

typedef struct VibrationPreset { unsigned char small_on; unsigned char large_intensity; unsigned short milliseconds; } VibrationPreset;

typedef struct PadDmaSnapshot {
 unsigned char packet[32];
 unsigned char actuator_direct[8];
 unsigned char actuator_alignment[8];
 unsigned char actuator_metadata[4][4];
 unsigned char combination_metadata[4][4];
 unsigned short modes[4];
 int generation; // signed newest-half comparison
 unsigned int find_retries;
 unsigned int length;
 unsigned char mode_config;
 unsigned char controller_id;
 unsigned char model;
 unsigned char data_ready;
 unsigned char mode_count;
 unsigned char mode_offset;
 unsigned char actuator_count;
 unsigned char combination_count;
 unsigned char _unknown_006c; // low byte of IOP word, external meaning unresolved
 unsigned char mode;
 unsigned char lock;
 unsigned char direct_size;
 unsigned char state;
 unsigned char request_state;
 unsigned char current_task;
 unsigned char run_task;
 unsigned char status70_bit;
 unsigned char requested_button_mask[4]; // packed at 0x75
 unsigned char supported_button_mask[4]; // packed at 0x79
 unsigned char reserved[3];
} PadDmaSnapshot;

typedef struct PadDirectCommand {
 unsigned int sequence;
 unsigned int command;
 unsigned int size;
 unsigned char payload[6];
 unsigned char _unknown_0012[0xe];
} PadDirectCommand;

typedef struct PadClientSlot {
 PadDmaSnapshot *dma_area;
 PadDirectCommand *direct_command;
 void *iop_destination;
 unsigned int dma_id;
 unsigned int open;
 unsigned int unused[2]; // cleared by port init, no linked client use
} PadClientSlot;

typedef struct BtlSaveResultController { unsigned char _unknown_0000[8]; int state; int ranking_result; unsigned char _unknown_0010[8]; int reward_amount; short modal_gate; unsigned char _unknown_001e[2]; void *presentation; unsigned char _unknown_0024[4]; void *dialog_presentation; unsigned char _unknown_002c[0xC]; struct SurvivalCourseDescriptor *descriptor; struct SurvivalRankingView *ranking_child; int character_id; int elapsed_seconds; int course_index; int result_kind; unsigned char _unknown_0050[4]; short ordinal; } BtlSaveResultController;

typedef struct SurvivalSaveCourse { unsigned char row; unsigned char group; unsigned char _unknown_0002[2]; void *opponents /* contiguous three-byte rows */; short battle_count; unsigned short counter_id; signed char counter_increment; unsigned char _unknown_000d; unsigned short reward_bonus; char *native_name; } SurvivalSaveCourse;

typedef struct SaveRpcClient { unsigned int active_request; unsigned char _unknown_0004[0x14]; unsigned int callback_gp; void *callback; void *callback_argument; } SaveRpcClient;

typedef struct SaveRpcPacket { unsigned char _unknown_0000[0x10]; unsigned int allocation_flags; unsigned char _unknown_0014[4]; unsigned int release_word; } SaveRpcPacket;

typedef struct ItemPickup { int serial; unsigned char _unknown_04[0xC]; struct ItemPickupMethods *methods; CollisionQueryList *collision_handle; void *auxiliary; unsigned char state; unsigned char _unknown_1d[3]; float position[4]; float velocity[4]; unsigned char _unknown_40[0x10]; float collection_scalar; unsigned char _unknown_54[8]; int side; unsigned char side_result_mode; unsigned char active_item; unsigned char authored_item; unsigned char _unknown_63; int state_counter; unsigned char _unknown_68[4]; int retry_countdown; unsigned char _unknown_70[4]; struct ItemPickup *next; unsigned char _unknown_78[8]; } ItemPickup;

typedef struct ItemInventorySlot { unsigned char item; unsigned char _unknown_01[3]; int count; } ItemInventorySlot;

typedef struct ItemPanel { ItemInventorySlot *slots[3]; void *animation; struct ItemSelectBadge *badge; void *selected_item_object; void *list; void *support_gauge; int side; int selected_slot; float wheel_offset; unsigned char _unknown_2c[4]; float base_position[4]; union { float position_offset[4]; struct { float offset_x; float vertical_offset; float offset_z; float offset_w; }; }; float wheel_origin[4]; unsigned char state; unsigned char activation_marker; unsigned char advance_marker; unsigned char event_marker; unsigned char _unknown_64[0x1c]; } ItemPanel;

typedef struct BattleItemPresentationManager { ItemPickup *pickups; unsigned char _unknown_04[0x68]; ItemPanel *panels[2]; unsigned char _unknown_74[4]; FukidasiList *notifications[2]; struct ItemDistinctUse *distinct_use; int next_pickup_serial; unsigned char _unknown_88[0x28]; unsigned char end_sequence_flag; } BattleItemPresentationManager;

typedef struct EnginePadContext {
 unsigned char display_counter;
 unsigned char display_divisor;
 unsigned char cri_polling_mode;
 unsigned char display_field_mode;
 unsigned short rcnt0_snapshot;
 unsigned char _unknown_0006[2];
 unsigned short display_width;
 unsigned short display_height;
 unsigned short display_buffer_height;
 unsigned char _unknown_000e[2];
 float display_vertical_factor;
 unsigned int packed_display_value;
 unsigned char _unknown_0018[4];
 PadRecord pads[2];
 unsigned char _unknown_010c[0x86];
 unsigned char frame_gate; // low3 bits gate ordinary callbacks/tasks and late held snapshot
 unsigned char _unknown_0193;
 unsigned int update_counter;
 unsigned char _unknown_0198[0x20];
 unsigned char display_field;
 unsigned char _unknown_01B9[7];
 void *display_scratch_cursor;
 unsigned char _unknown_01C4[4];
 RenderPool *render_pool;
 RenderDmaTag *submitted_chain;
 RenderDmaTag *master_chain;
 RenderDmaTag *master_insertion;
 RenderDmaTag *setup_packet;
 unsigned char _unknown_01dc[4];
 RenderDmaTag master_templates[2][6];
 unsigned char _unknown_02a0[8];
 unsigned short requested_display_width; // +0x2A8
 unsigned short requested_display_height; // +0x2AA
 signed char setup_request;
 unsigned char pacing_bypass;
 unsigned char field_adjustment;
 unsigned char display_bank;
 GsDisplayEnvironment display_environments[2];
 unsigned char draw_environment_packets[2][0xf0];
 unsigned long long selected_display_values[2][2];
 void *cdvd_recovery_callback;
 signed char cdvd_recovery_state;
 unsigned char _unknown_0505;
 unsigned char cdvd_recovery_suppressed;
 unsigned char _unknown_0507;
 void *cdvd_recovery_task;
 unsigned char _unknown_050c[0x14];
 void *early_callback;
 unsigned char _unknown_0524[0xc];
} EnginePadContext;

typedef struct ModeSelectInput {
 int state;
 int active_count;
 int physical_slots[7];
 int selected_index;
 float carousel_displacement;
 unsigned char _unknown_002c[4];
 unsigned int pressed;
 unsigned int repeat;
 unsigned int held;
 unsigned int port_pressed[2];
 int transition_handle;
 int result;
 int result_countdown;
 short pulse_counter;
 unsigned char _unknown_0052[6];
 unsigned char input_source;
 unsigned char _unknown_0059[3];
 int scripted_target;
 SaveDialogController *save_dialog;
 unsigned char _unknown_0064[4];
 void *render_context;
 void *prompt_context;
 void *legend_sprite;
 void *button_sprite;
 CcsAnimationPlayer *background_player; CcsAnimationPlayer *foreground_player; CcsAnimationPlayer *decoration_player; unsigned char _unknown_0084[4];
 unsigned char arrow_active[2];
 unsigned char _unknown_008a[2];
 CcsAnimationPlayer *arrow_players[2];
 CcsAnimationPlayer *common_decoration;
 CcsAnimationPlayer *item_players[7];
 unsigned char _unknown_00b4[8];
 int visual_slot;
 void *selection_visual;
 int modal_kind;
 UiPanel *prompt_panel;
 FrontEndModal *back_modal;
 FrontEndModal *prompt_choices;
} ModeSelectInput;

typedef struct CharacterSelectorInput {
 int state;
 int state1_blocked; // fixed fighter flag
 int state59_blocked; // fixed support: 0 editable, 1 native, 2 sentinel25, 3 sentinel26
 int side;
 unsigned char linked_mode; // Manual0, Auto1
 unsigned char _unknown_0011[3];
 int color;
 int form;
 unsigned char _unknown_001c[4];
 int fighter_column;
 int fighter_row;
 float fighter_anchor;
 float fighter_transition;
 int support_index;
 int support_page;
 float support_anchor;
 float support_transition;
 int random_category;
 int random_counter;
 int random_update_guard;
 unsigned char _unknown_004c[4];
 unsigned int pressed;
 unsigned int repeat;
 unsigned int held;
 unsigned int navigation;
 unsigned char navigation_countdown;
 unsigned char _unknown_0061[3];
 float pulse_phase;
 float pulse_request;
 float portrait_visibility;
 int support_memory_fighter;
 CharacterSelectData *data;
 CcsAnimationPlayer *presentation_players[4];
 int support_presentation_state;
 int support_presentation_request;
 int support_animation_complete;
 CcsAnimationPlayer *final_animation;
 unsigned char _unknown_0098[8];
 int final_animation_complete;
 unsigned char _unknown_00a4[0x14];
 void *linked_window;
 float recursive_easing;
 unsigned char _unknown_00c0[8];
 int controlling_port;
} CharacterSelectorInput;

typedef struct ContestInputState {
 void *render_context; // +0x00
 short mode; // +0x04
 short state; // +0x06
 short pending_state; // +0x08; -1 when none
 short attacker_side; // +0x0A
 unsigned char _unknown_000c[8];
 short cpu_tier; // +0x14
 short cpu_counter[2]; // +0x16
 unsigned char cpu[2]; // +0x1A
 unsigned char _unknown_001c[0x40];
 signed char result_a[2]; // +0x5C
 signed char result_b[2]; // +0x5E
 unsigned char time_bar_enabled; // +0x60
 unsigned char _unknown_0061;
 short time_bar_state; // +0x62
 int elapsed; // +0x64
 int time_limit; // +0x68; copied from configured_time_limit in state 7
 int configured_time_limit; // +0x6C
 unsigned char _unknown_0070[4];
 float meter; // +0x74; positive toward side 0
 unsigned char attacker_result; // +0x78
 unsigned char defender_result; // +0x79
 unsigned char _unknown_007a[0x12];
 short count[2]; // +0x8C
 unsigned char _unknown_0090[0x30];
 short feedback_state[2]; // +0xC0
 short feedback_counter[2]; // +0xC4
 unsigned char _unknown_00c8[0xc];
 unsigned char active; // +0xD4
 unsigned char finishing; // +0xD5
 unsigned char result_a_wait; // +0xD6
 unsigned char result_b_wait; // +0xD7
 unsigned char status; // +0xD8
 unsigned char status_flags; // +0xD9; separate from status
 unsigned char _unknown_00da[2];
 void *vtable; // +0xDC
} ContestInputState;

typedef struct ContestCommandInput { ContestInputState base; unsigned char _unknown_00e0[0x2e]; short pending[2]; unsigned char _unknown_0112[0x200]; short position[2]; } ContestCommandInput;

typedef struct ContestComboInput { ContestInputState base; unsigned char _unknown_00e0[0xa]; short rearm[2]; short required_button; unsigned char _unknown_00f0[8]; short pending[2]; short lockout[2]; } ContestComboInput;

typedef struct ContestTimingInput { ContestInputState base; unsigned char _unknown_00e0[0x50]; unsigned char required_button[2]; short lockout[2]; unsigned char matched[2]; short launch_countdown[2]; struct ContestTimingNote notes[2][5]; } ContestTimingInput;

typedef struct EffectAuxList { int count; EffectAuxVisual *head; EffectAuxVisual *tail; void *vtable; } EffectAuxList;

typedef struct SupportScriptResourceRow { char token[4]; unsigned char variant; } SupportScriptResourceRow;

typedef struct ChakraAggregateController {
    unsigned char _unknown_0000[0x4cc];
    Fighter *fighter;
    unsigned char _unknown_04d0[0xb26];
    short input_press_count; // +0xFF6; signed wrapping count incremented by binding1_shared_press_b
    unsigned char _unknown_0ff8[0x38];
    float accumulated_chakra;
    float increment;
    float base_debit;
} ChakraAggregateController;

typedef struct ChakraDebitGate {
    unsigned char _unknown_0000[0x14];
    unsigned int flags;
} ChakraDebitGate;

typedef struct ChakraDebitController {
    unsigned char _unknown_0000[0x4cc];
    Fighter *fighter;
    unsigned char _unknown_04d0[0x80];
    ChakraDebitGate *gate;
} ChakraDebitController;

typedef struct GuardHitDispatcher {
    unsigned char _unknown_0000[0x20c];
    unsigned int processed;
} GuardHitDispatcher;

typedef union ProjectileGuideTime { float time; unsigned int bits; } ProjectileGuideTime;

typedef struct ProjectileGuideKey { ProjectileGuideTime timestamp; float value[3]; float tail[6]; } ProjectileGuideKey;

typedef struct ProjectileGuideChannel { unsigned short flags; short key_count; ProjectileGuideKey *keys; unsigned char _unknown_0008[0xC]; } ProjectileGuideChannel;

typedef struct ProjectileGuide { unsigned short flags; short channel_count; ProjectileGuideChannel *channels; float cursor; float endpoint; float bias[4]; } ProjectileGuide;

typedef struct ProjectileBirdBlock { int base; int range; int percentage; unsigned char _unknown_000c[4]; float speed_spread; } ProjectileBirdBlock;

typedef struct ProjectileCarrierResource { char *name; unsigned int retained_word; } ProjectileCarrierResource;

typedef struct ProjectileCarrierHeader { unsigned int word0; void *rows; } ProjectileCarrierHeader;

typedef struct ProjectileCarrierRowPrefix { short resource_id; short advance_control; short start; short step; } ProjectileCarrierRowPrefix;

typedef struct ProjectileCarrierMovementRow { ProjectileCarrierRowPrefix prefix; unsigned short flags; short event; float horizontal; float vertical; float damping; float gravity; unsigned char _unknown_001c[0x30]; } ProjectileCarrierMovementRow;

typedef struct ProjectileFudaScheduleRow { int counter; unsigned char _unknown_0004[0xC]; float offset[4]; unsigned char retire; unsigned char _unknown_0021[3]; int child_config; unsigned char _unknown_0028[8]; } ProjectileFudaScheduleRow;

typedef struct ProjectileHoming {
Projectile base;
int steering_start;
int steering_end;
unsigned int control_reserved;
float turn_scalar;
short retire_threshold;
unsigned char steering_enabled;
unsigned char control_supplied;
} ProjectileHoming;

typedef struct ProjectileSoundWave {
Projectile base;
unsigned char _unknown_0290[0x20];
float event_threshold;
short countdown;
unsigned char phase;
} ProjectileSoundWave;

typedef struct ProjectileKibakukunai {
Projectile base;
unsigned char _unknown_0290[0x44];
int phase;
unsigned char repeated_event;
unsigned char _unknown_02d9[0x3];
float countdown;
} ProjectileKibakukunai;

typedef struct ProjectileClayBird {
Projectile base;
ProjectileGuide * guide;
float clock;
float cutoff_adjustment;
int guide_selection;
float sample_position[4];
unsigned char _unknown_02b0[0x10];
ProjectileBirdBlock * supplied_block;
float motion_multiplier;
} ProjectileClayBird;

typedef struct ProjectileClayBirdU {
Projectile base;
float clock;
float deadline;
float turn_scalar;
unsigned char _unknown_029c[0x10];
ProjectileBirdBlock * supplied_block;
float motion_multiplier;
} ProjectileClayBirdU;

typedef struct ProjectileClaySpeed {
Projectile base;
unsigned char clock_enabled;
unsigned char _unknown_0291[0x3];
float clock;
float deadline;
float recovery_threshold;
unsigned char _unknown_02a0[0x70];
float vertical_speed;
float stored_speed;
float horizontal_direction;
int recovery_count;
unsigned char _unknown_0320[0x4];
float motion_multiplier;
unsigned char _unknown_0328[0x8];
float proximity;
} ProjectileClaySpeed;

typedef struct ProjectileInkSnake {
Projectile base;
void * owned_reference;
float clock;
short deadline;
unsigned char _unknown_029a[0x6];
float anchor[4];
float bias[4];
float bias_countdown;
float motion_multiplier;
unsigned char flags;
} ProjectileInkSnake;

typedef struct ProjectileInkBird {
Projectile base;
void * owned_reference;
ProjectileGuide * guide;
unsigned char _unknown_0298[0x4];
float clock;
short deadline;
short fighter_selector;
unsigned char _unknown_02a4[0xc];
float target[4];
unsigned char _unknown_02c0[0x20];
float retarget_start;
float retarget_end;
float motion_multiplier;
unsigned char flags;
} ProjectileInkBird;

typedef struct ProjectileInkMouse {
Projectile base;
void * owned_reference;
float clock;
short deadline;
unsigned char _unknown_029a[0x7a];
float stored_speed;
float horizontal_direction;
unsigned char _unknown_031c[0x4];
float motion_multiplier;
} ProjectileInkMouse;

typedef struct ProjectileTentenMotion {
Projectile base;
unsigned char _unknown_0290[0x20];
float launch_direction[4];
int phase_count;
float vertical_accumulator;
} ProjectileTentenMotion;

typedef struct ProjectileBoomerang {
Projectile base;
short window_start;
short window_end;
float turn_scalar;
float turn_amount;
float clock;
} ProjectileBoomerang;

typedef struct ProjectileSandPellet {
Projectile base;
unsigned char phase;
unsigned char _unknown_0291[0x1];
short countdown;
unsigned char _unknown_0294[0x1c];
float fighter_direction;
unsigned char _unknown_02b4[0xc];
float fighter_snapshot[4];
float initial_distance;
float remaining_distance;
} ProjectileSandPellet;

typedef struct ProjectileIronRainMotion {
Projectile base;
unsigned char phase;
unsigned char _unknown_0291[0x1];
short countdown;
unsigned char _unknown_0294[0x40];
float remaining_distance;
unsigned char _unknown_02d8[0x18];
float scale_limit;
} ProjectileIronRainMotion;

typedef struct ProjectileChiyoKunai {
Projectile base;
unsigned char _unknown_0290[0x40];
float remaining_distance;
unsigned char _unknown_02d4[0xc];
short launch_delay;
} ProjectileChiyoKunai;

typedef struct ProjectileNwvMotion {
Projectile base;
unsigned char _unknown_0290[0x4];
short phase_count;
} ProjectileNwvMotion;

typedef struct ProjectileBoundMotion {
Projectile base;
short count;
unsigned char _unknown_0292[0x2];
float gravity;
float horizontal_damping;
float bounce_factor;
float terminal_speed;
unsigned char _unknown_02a4[0x34];
float rotation_scalar;
unsigned char _unknown_02dc[0x34];
unsigned int contact_flags;
unsigned char _unknown_0314[0xc];
float previous_position[4];
} ProjectileBoundMotion;

typedef struct ProjectileKunaiBomb {
Projectile base;
float gravity;
float clock;
short phase;
unsigned char flags;
} ProjectileKunaiBomb;

typedef struct ProjectileDdrWave {
Projectile base;
float angle;
float angle_rate;
unsigned char _unknown_0298[0x8];
float anchor[4];
} ProjectileDdrWave;

typedef struct ProjectileDdrBullet {
Projectile base;
float deadline;
float angle;
float angle_rate;
float amplitude;
float anchor[4];
} ProjectileDdrBullet;

typedef struct ProjectileYari {
Projectile base;
float vertical_speed;
float vertical_increment;
} ProjectileYari;

typedef struct ProjectilePupBullet {
Projectile base;
float saved_position[4];
float remaining_distance;
int child_parameter;
} ProjectilePupBullet;

typedef struct ProjectileStickFuda {
Projectile base;
float countdown;
} ProjectileStickFuda;

typedef struct ProjectileFixedFire {
Projectile base;
short startup_countdown;
short active_countdown;
} ProjectileFixedFire;

typedef struct ProjectileSiwTrapMotion {
Projectile base;
short count;
short fighter_state;
} ProjectileSiwTrapMotion;

typedef struct ProjectileInkReference {
unsigned char _unknown_0000[0xc];
float step;
} ProjectileInkReference;

typedef struct ProjectileCarrierMember {
unsigned char _unknown_0000[0x20];
float position[4];
} ProjectileCarrierMember;

typedef struct BattleInputPhaseOverride { unsigned char _unknown_0000[0xa50]; unsigned char force_history; } BattleInputPhaseOverride;

typedef struct BindingPressController { unsigned char _unknown_0000[0x60]; unsigned short state_flags; } BindingPressController;

typedef struct SharedBindingInputReader {
 unsigned char _unknown_0000[0x13c];
 unsigned int controlled_press;
 unsigned char _unknown_0140[4];
 SharedSkillInputEvent *input_event; // +0x144; initialized 0x14-byte input object
 unsigned short total_input_events; // +0x148; halfword wrapping count
 unsigned short pending_input_events; // +0x14A; contribution gate
 unsigned short input_event_age; // +0x14C
 unsigned short input_event_age_limit; // +0x14E; zero disables aging
 unsigned char input_events_enabled; // +0x150
 unsigned char _unknown_0151[0x1CB];
 BindingPressController *controller;
 unsigned char _unknown_0320[0x30];
 int side;
 unsigned char _unknown_0354[0x35];
 unsigned char controller_enabled;
} SharedBindingInputReader;

typedef struct Mwo3Header {
 unsigned int magic;
 unsigned int kind;
 unsigned int linked_base;
 unsigned int text_size;
 unsigned int data_size;
 unsigned int bss_size;
 void **constructor_begin;
 void **constructor_end;
 char product_label[0x20];
} Mwo3Header;

typedef struct CompilerCleanupNode {
 struct CompilerCleanupNode *previous_head;
 void *cleanup_callback;
 void *object;
} CompilerCleanupNode;

typedef struct BtlRecordDescriptor {
 short count;
 unsigned char _unknown_02[2];
 short *keys;
 unsigned char *records;
} BtlRecordDescriptor;

typedef struct CollectionControllerVtable {
 void *type_info;
 unsigned int zero;
 void *delete_method;
 void *initialize_method;
 void *update_method;
 void *present_method;
} CollectionControllerVtable;

typedef struct CollectionController {
 unsigned char _unknown_00[8];
 CollectionControllerVtable *vtable;
} CollectionController;

typedef struct CollectionOwner {
 void *container;
 void *owned_resources[11];
 unsigned char _unknown_30[0x20];
 CollectionController *controllers[10];
 void *nested_owner;
 unsigned char _unknown_7c[4];
} CollectionOwner;

typedef struct BtlRecordOwnerRow {
 void *definition;
 unsigned int mutable1;
 unsigned int mutable2;
} BtlRecordOwnerRow;

typedef struct BtlRecordOwner {
 short state;
 short selected_side;
 unsigned int reset_word;
 unsigned int context_value;
 unsigned char tier;
 unsigned char _unknown_0d[3];
 int fade_handle;
 BtlRecordOwnerRow rows[28];
 void *polymorphic_owners[2];
 unsigned char _unknown_16c[0x10];
 void *owned_17c;
 void *owned_180;
 void *owned_184;
} BtlRecordOwner;

typedef struct BtlSessionRoot {
 unsigned char _unknown_00[0x30];
 void *root;
} BtlSessionRoot;

typedef struct ProjectileAuxMotion { Projectile base; void *auxiliary; } ProjectileAuxMotion;

typedef struct ProjectileSnwLauncher { ProjectileHoming base; unsigned char _unknown_02a4[0x10]; short emission_threshold; } ProjectileSnwLauncher;

typedef struct ProjectileParabolaChild { Projectile base; unsigned char _unknown_0290[2]; short phase; unsigned char _unknown_0294; unsigned char child_flag; } ProjectileParabolaChild;

typedef struct TaskCleanupRecord {
 struct TaskCleanupRecord *next;
 char *name;
 short initial_priority;
 short thread_id;
 void *entry;
 unsigned short runtime_flags;
 unsigned short control_flags;
 int wake_gate;
 unsigned int stack_size;
 void *stack;
 void *cleanup_argument;
 void *cleanup_callback;
 unsigned int payload[7]; // caller-owned words at 0x28..0x40; manager does not interpret
 unsigned char _unknown_0044[8]; // constructor zeros word 0x44, halfword 0x48 and byte 0x4A; byte 0x4B untouched
} TaskCleanupRecord;

typedef struct ProjectileOrochimaruMotion { Projectile base; unsigned char _unknown_0290[0x10]; float horizontal_speed; float horizontal_increment; float horizontal_limit; float vertical_speed; float vertical_increment; float vertical_limit; unsigned char flags; } ProjectileOrochimaruMotion;

typedef struct ProjectileSiwChild { Projectile base; unsigned char _unknown_0290[8]; float value298; unsigned char _unknown_029c[4]; float value2a0; unsigned char _unknown_02a4[4]; float value2a8; float value2ac; } ProjectileSiwChild;

typedef struct ItemPickupDecayEntry { float alpha; unsigned char _unknown_04[0x1c]; } ItemPickupDecayEntry;

typedef struct ItemChakraPickup { ItemPickup base; int collection_latched; unsigned char _unknown_84[0x2c]; ItemPickupDecayEntry decay[7]; float final_decay_alpha; unsigned char _unknown_194[0xc]; } ItemChakraPickup;

typedef struct ItemSelectBadge { int side; unsigned char _unknown_04[0xC]; float offset[4]; float scale; int sprite; unsigned char item_select; unsigned char _unknown_29[7]; } ItemSelectBadge;

typedef struct ItemDistinctUse { unsigned char codes[116]; int count; unsigned int work; unsigned char flags; unsigned char inventory_checked; } ItemDistinctUse;

typedef struct ItemCacheEntry { unsigned char code; signed char count; } ItemCacheEntry;

typedef struct ItemCacheSide { ItemCacheEntry entries[3]; } ItemCacheSide;

typedef struct ItemSeedRow { short character_id; signed char code; unsigned char _unknown_03; } ItemSeedRow;

typedef struct ItemThresholdRow { short threshold; signed char code; signed char count; } ItemThresholdRow;

typedef struct ItemTimingLane { signed char start; signed char end; unsigned char _unknown_02[2]; short cooldown; unsigned short rate; } ItemTimingLane;

typedef struct ItemTimingRecord { ItemTimingLane lanes[3]; } ItemTimingRecord;

typedef struct ItemRandomDistributionRow { int pool_kind; int threshold_increment; } ItemRandomDistributionRow;

typedef struct ItemPickupMethods { unsigned char _unknown_00[8]; void *admit; void *state1; void *state2; void *state6; void *state7; void *state5; unsigned char _unknown_20[4]; void *retained_side; unsigned char _unknown_28[0xC]; void *collect; unsigned char _unknown_38[4]; void *destroy; } ItemPickupMethods;

typedef struct ItemTnd001Work { unsigned char _unknown_00[0x500]; int side; unsigned char _unknown_504[0xaf2]; short action_age; short action_limit; unsigned char _unknown_ffa[0x96]; unsigned char phase4_event; unsigned char _unknown_1091[0x167]; short drop_countdown; unsigned char _unknown_11fa[0x6f9]; unsigned char phase4_branch; } ItemTnd001Work;

typedef struct CcsProjectionDescriptor {
    CcsRecord *record;
    unsigned short ordered_slot;
    unsigned short target_x;
    unsigned short target_y;
    unsigned short width;
    unsigned short height;
    unsigned short depth_x;
    unsigned short depth_y;
    unsigned char composite_passes;
    unsigned char offset_multiplier;
    float projection_scalar;
} CcsProjectionDescriptor;

typedef struct CcsProjectionBucket {
    struct CcsProjectionBucket *next;
    unsigned char strength_key;
    unsigned char _pad_0005[3];
    void *packet_head;
    void *packet_tail;
} CcsProjectionBucket;

typedef struct CcsPacketRing {
    unsigned char *buffer;
    int semaphore;
    void *command_target;
    unsigned short queued_count;
    unsigned short write_index;
    unsigned short read_index;
    short count_snapshot;
    unsigned char _unknown_0014[2];
    unsigned short value_3f;
    unsigned int unavailable_slots;
} CcsPacketRing;

typedef struct CcsPacketBatchHeader {
    unsigned char _uninterpreted_0000[8];
    unsigned int packet_count;
    unsigned int words_per_packet;
} CcsPacketBatchHeader;

typedef struct CcsCommandTarget {
    unsigned char _unknown_0000[0x18];
    void *callback;
    void *callback_argument;
    unsigned char _unknown_0020[0xC];
    unsigned int command_bits;
} CcsCommandTarget;

typedef struct CcsRenderEnvironment {
    unsigned char _unknown_0000[0x3C];
    struct RendererTransformState *renderer;
    unsigned char _unknown_0040[0x8C];
    void *projection_controller;
    float projection_direction[4];
    float projection_scalar;
    unsigned char projection_strength;
} CcsRenderEnvironment;

typedef struct CcsSceneObjectDescriptor {
    CcsRecord *record;
    CcsRecord *linked_record;
    unsigned int metadata_value;
    CcsRecord *model_record;
    CcsRecord *shadow_model_record;
    CcsRecord *morph_controller_record;
    unsigned char _unknown_0018[0xC];
} CcsSceneObjectDescriptor;

typedef struct CcsMaterialDescriptor {
    CcsRecord *record;
    void *next;
    CcsRecord *texture_record;
    float alpha; short u_offset; short v_offset; short u_scale; short v_scale;
} CcsMaterialDescriptor;

typedef struct CcsEffectDescriptor {
    CcsRecord *record;
    unsigned char _unknown_0004[4];
    CcsRecord *texture_record;
    unsigned char _unknown_000C[8]; unsigned short flags;
    unsigned short frame_count;
    float projection_offset; float coordinate_parameters[4]; unsigned int packed_dimensions; struct CcsEffectFrame *frames;
} CcsEffectDescriptor;

typedef struct CcsModelDescriptor {
    CcsRecord *record;
    unsigned char _unknown_0004[0xc]; float bounds_minimum[4]; float bounds_maximum[4]; float bounds_midpoint[4]; struct CcsCompositionDescriptor *composition; float position_scale;
    unsigned int runtime_flags;
    float header_value; unsigned char extra_pass_color[3]; unsigned char extra_pass_selector; float extra_pass_width;
    unsigned char *palette_indices;
    unsigned char palette_count;
    unsigned char blend_selector;
    unsigned short part_count;
    CcsModelMesh parts[1];
} CcsModelDescriptor;

typedef struct CcsCompositionDescriptor {
    CcsRecord *record;
    void *next;
    unsigned short child_count;
    unsigned char flags;
    unsigned char _pad_000B;
    CcsRecord **children;
    short *parent_indexes;
    void *child_transforms;
    CcsRelationData *attachments;
} CcsCompositionDescriptor;

typedef struct CcsCamera {
    CcsRecord *record;
    unsigned char _unknown_0004[8];
    float view_scalar;
    float matrix[16];
} CcsCamera;

typedef struct CcsLightDescriptor {
    CcsRecord *record;
    void *next;
    unsigned char kind;
    unsigned char selector;
    unsigned char _pad_000A[2];
} CcsLightDescriptor;

typedef struct CcsBoundsDescriptor {
    CcsRecord *record;
    struct CcsBoundsDescriptor *next;
    CcsRecord *linked_record;
    unsigned char _unknown_000c[4];
    float minimum[4];
    float maximum[4];
    float midpoint[4];
} CcsBoundsDescriptor;

typedef struct CcsPositionMarker {
    CcsRecord *record;
    unsigned char _unknown_0004[0xC];
    float position[4];
} CcsPositionMarker;

typedef struct CcsTransformMarker {
    CcsRecord *record;
    unsigned char _unknown_0004[0xC];
    float position[4];
    float euler_radians[4];
} CcsTransformMarker;

typedef struct CcsOrderedControllerDescriptor {
    CcsRecord *record;
    unsigned short ordered_slot;
    unsigned char _unknown_0006[2];
} CcsOrderedControllerDescriptor;

typedef struct CcsBinaryBlob {
    CcsRecord *record;
    unsigned int byte_length;
    unsigned char payload[1];
} CcsBinaryBlob;

typedef struct CcsTransferDescriptor {
    unsigned char _unknown_0000[4];
    void *pixels;
    unsigned int pixel_qwords;
    unsigned short transfer_packing;
    unsigned char flags;
    unsigned char ownership_flags;
    unsigned short source_base_packing; unsigned char _unknown_0012[2]; unsigned short destination_base_packing; unsigned char _unknown_0016[0xa];
} CcsTransferDescriptor;

typedef struct CcsTextureChunk {
    CcsRecord *record;
    unsigned char _unknown_0004[4]; unsigned long long tex0_state; unsigned long long tex1_state; unsigned long long miptbp1_state; unsigned long long clamp_state;
    CcsTransferDescriptor *levels;
    CcsImageTransferGroup *transfer_group;
    unsigned short draw_flags; unsigned short width; unsigned short height; unsigned char width_log2; unsigned char height_log2; unsigned char extra_levels; unsigned char pixel_format; unsigned char alpha_reference;
    unsigned char flags;
    void *clut;
    void *vtable;
    unsigned char _unknown_0044[4];
} CcsTextureChunk;

typedef struct CcsClut {
    CcsRecord *record;
    unsigned char _unknown_0004[4]; unsigned long long tex0_state;
    CcsTransferDescriptor *transfer;
    CcsImageTransferGroup *transfer_group;
    unsigned short transfer_flags;
    unsigned short width;
    unsigned short height;
    unsigned char color_format;
    unsigned char pixel_format;
    unsigned char flags;
    unsigned char _unknown_0021[7];
} CcsClut;

typedef struct CcsNestedTableInputHeader {
    unsigned int target_id;
    unsigned short group_count;
    unsigned short record_id_count;
} CcsNestedTableInputHeader;

typedef struct CcsNestedGroupInputHeader {
    unsigned short record_id_index;
    unsigned short ignored;
    unsigned short pair_count;
    unsigned short item_count;
} CcsNestedGroupInputHeader;

typedef struct CcsNestedItemInputHeader {
    unsigned short element_count;
    unsigned short flags;
    unsigned char opaque_bytes[4];
    unsigned short opaque_halfwords[2];
} CcsNestedItemInputHeader;

typedef struct CcsNestedTable {
    CcsRecord *record;
    unsigned short group_count;
    unsigned char _unwritten_0006[2];
    CcsRecord **group_records;
    struct CcsNestedGroup *groups[1];
} CcsNestedTable;

typedef struct CcsNestedGroup {
    unsigned short pair_count;
    unsigned short item_count;
    unsigned short *pairs;
} CcsNestedGroup;

typedef struct CcsNestedItem {
    unsigned short *primary;
    unsigned short element_count;
    unsigned short flags;
    unsigned char opaque_bytes[4];
    unsigned short opaque_halfwords[2];
} CcsNestedItem;

typedef struct CcsShadowAnimationOwner {
    void *vtable;
    unsigned char _unknown_0004[0x38];
} CcsShadowAnimationOwner;

typedef struct CcsMorpherRuntime {
    unsigned char _unknown_0000[0xC];
    void *vtable;
    unsigned short source_count; unsigned char _unknown_0012[2]; CcsMorphSource sources[32];
} CcsMorpherRuntime;

typedef struct CcsDrawEnvParameterRuntime {
    unsigned char _unknown_0000[4];
    void *vtable;
} CcsDrawEnvParameterRuntime;

typedef struct CcsBlurParameterRuntime {
    void *vtable;
} CcsBlurParameterRuntime;

typedef struct CcsLightRuntime {
    unsigned char _unknown_0000[0xA4];
    void *vtable;
} CcsLightRuntime;

typedef struct FrontEndOuterState { int state; int title_result; } FrontEndOuterState;

typedef struct TitleController {
 int state;
 int idle_countdown;
 int result;
 int selection;
 int transition_handle;
 unsigned char _unknown_0014[4];
 int presentation_phase;
 CcsAnimationPlayer *player;
 CcsAnimationDescriptor *first_animation;
 CcsAnimationDescriptor *second_animation;
 unsigned int presentation_complete;
 CcsAnimationPlayer *item_players[2]; unsigned char _unknown_0034[0x14];
} TitleController;

typedef struct FrontEndTransient { int phase; int countdown; int mode_result; unsigned int reserved_word; int sentinel; } FrontEndTransient;

typedef struct BtlProcessTable { void *type_info; unsigned int zero; void *callback; } BtlProcessTable;

typedef struct BtlProcess {
 int state;
 int delay;
 unsigned char _unknown_0008[0xc];
 int entry_type;
 int entry_type_enabled;
 unsigned char _unknown_001c[0x18];
 void *character_select;
 void *stage_select;
 BtlRecordOwner *result_metrics;
 BtlProcessTable *methods;
} BtlProcess;

typedef struct ModalChoiceState {
 void *head; float x; float y; float row_extra;
 unsigned short automatic_completion;
 short result;
 int count;
 int selection;
 unsigned char _unknown_001c[4];
 unsigned short completion_threshold;
 unsigned short completion_counter;
 unsigned short confirmation_step;
 unsigned short confirmation_counter;
 unsigned char event_flags;
 unsigned char navigation_flags;
} ModalChoiceState;

typedef struct FrontEndModal {
 unsigned char _unknown_0000[0x7c];
 ModalChoiceState *choices;
} FrontEndModal;

typedef struct ResultMetricDescriptor { short coefficient; short unit_index; signed char cap_selector; unsigned char _unknown_05[3]; char *text; } ResultMetricDescriptor;

typedef struct ResultBucketRow { int threshold; int contribution; } ResultBucketRow;

typedef struct ItemBattleSpriteRecord { unsigned char mode; unsigned char flags; unsigned short u; unsigned short v; unsigned short width; unsigned short height; unsigned char layer; unsigned char _unknown_0b; } ItemBattleSpriteRecord;

typedef struct CcsGeneratorPacketEntry {
    CcsRecord *generator_record;
    CcsRecord *attachment_record;
    CcsRecord *auxiliary_record;
    unsigned int opaque_word;
    unsigned short command_byte_count;
    unsigned char _pad_0012[2];
    unsigned char *commands;
} CcsGeneratorPacketEntry;

typedef struct CcsCameraPlaybackOwner {
    unsigned char _unknown_0000[0x10C];
    CcsCamera *active_camera;
} CcsCameraPlaybackOwner;

typedef struct ProjectileCarrierCommandView {
    Projectile base;
    unsigned char _unknown_0290[0x1a0];
    int command;
    int command_table_index;
    int command_clock;
    ProjectileCarrierHeader *selected_header;
    unsigned int retained_resource_word;
    int row_index;
    ProjectileCarrierHeader *command_table;
    ProjectileCarrierResource *resource_table;
    float horizontal_speed;
    float vertical_speed;
    float gravity_multiplier;
} ProjectileCarrierCommandView;

typedef struct ProjectileBoundVtableView {
    unsigned char _unknown_0000[0x5c];
    void *integrate;
    void *rotate;
    void *choose_emission;
} ProjectileBoundVtableView;

typedef struct ProjectileCarrierVtableView {
    unsigned char _unknown_0000[0x5c];
    void *integrate;
    void *update_command;
    void *command_callback;
} ProjectileCarrierVtableView;

typedef struct ProjectilePoseVtableView { unsigned char _unknown_0000[0x20]; void *update_orientation; unsigned char _unknown_0024[0x28]; void *build_transform; } ProjectilePoseVtableView;

typedef struct DamageCounter { unsigned char _unknown_00[0x10]; float current; float maximum; } DamageCounter;

typedef struct DamagePopup { unsigned char _unknown_00[0xc]; short lifetime; unsigned char _unknown_0e[2]; float percentage; short digits[4]; short digit_count; } DamagePopup;

typedef struct SkillDamageDescriptor { unsigned char _unknown_00[0xf4]; float guard_damage_multiplier; } SkillDamageDescriptor;

typedef struct CcsGeneratorChild {
    unsigned char _unknown_0000[4];
    CcsRecord *record;
    unsigned char color_selector;
    unsigned char texture_selector;
    unsigned char flags;
    unsigned char _unknown_000B;
} CcsGeneratorChild;

typedef struct CcsGeneratorDescriptor {
    CcsRecord *record;
    unsigned char _unknown_0004[8];
    float alpha_inner; // +0x0C
    float distance_min; // +0x10
    float alpha_outer; // +0x14
    float distance_max; // +0x18
    float alpha_scale; // +0x1C
    float color_alpha; // +0x20
    float random_alpha_bound; // +0x24
    CcsGeneratorChild *children;
    unsigned char _unknown_002C[2];
    unsigned char child_count_flags; // low nibble is child count
    unsigned char _unknown_002F[0xB];
    short registration_gate; // negative permits child registration
} CcsGeneratorDescriptor;

typedef struct AudioControl { signed char program; unsigned char stream; unsigned char channel; signed char default_parameter; signed char scalar_cap; unsigned char opaque5; short distance_scale; } AudioControl;

typedef struct AudioPendingStream { int bank; int member; int slot; int alternate_bank; unsigned char pending; unsigned char _unknown_11[3]; } AudioPendingStream;

typedef struct AudioRequestContext { int battle_music_override; unsigned char _unknown_04[6]; short fighter_ids[2]; unsigned char _unknown_0e[2]; int equal_id_selector; AudioPendingStream pending[4]; unsigned char _unknown_64[8]; int request_selector; unsigned char _unknown_70[8]; } AudioRequestContext;

typedef struct AudioBankDescriptor { int file_offset; int allocation_size; int sample_extent; } AudioBankDescriptor;

typedef struct AudioArchiveDescriptor { short archive_handle; unsigned char _unknown_02[2]; short start_parameter; short member_count; } AudioArchiveDescriptor;

typedef struct AudioPacket { unsigned int capacity; unsigned int used; unsigned char payload[0xEC]; unsigned char _unknown_f4[8]; unsigned int trailer; } AudioPacket;

typedef struct AudioStreamBufferRow { unsigned int opaque; AudioPacket *buffer; } AudioStreamBufferRow;

typedef struct AudioAppendStreams { unsigned char _unknown_00[8]; unsigned int count; AudioStreamBufferRow *rows; } AudioAppendStreams;

typedef struct AudioAppendHandle { unsigned int opaque; AudioAppendStreams *streams; } AudioAppendHandle;

typedef struct AudioCommandContext { int volume; int music_volume; int synth_level; int output_mode; unsigned char _unknown_10[0xC]; unsigned char ready; unsigned char loading; unsigned char _unknown_1e[2]; unsigned char bank_transaction; unsigned char poll_enabled; short synth_levels[5]; unsigned char _unknown_2c[4]; int player_allocations[2]; unsigned char _unknown_38[4]; int mode_allocation; int initial_placement; int placement; unsigned char _unknown_48[4]; unsigned char rpc_lock; unsigned char _unknown_4d; unsigned char stop_pending; unsigned char _unknown_4f[5]; int mode; unsigned char bank_state; unsigned char bank_operation; unsigned char _unknown_5a[2]; int bank_argument; unsigned char _unknown_60[0x1C]; int hardware_operations[8]; int hardware_arguments[8]; unsigned char retain_banks; unsigned char reapply_music_gain; unsigned char resend_synth_level; unsigned char _unknown_bf; int current_music_track; unsigned char _unknown_c4[0x14]; unsigned char cinematic_stop; unsigned char _unknown_d9[0x6F]; unsigned char level_fade_active; unsigned char _unknown_149[3]; short level_fade_target; unsigned char _unknown_14e[2]; int level_fade_step; int level_fade_frames; int level_fade_current; unsigned char _unknown_15c; unsigned char tokens[8]; unsigned char _unknown_165[0x13]; int operation_slot; } AudioCommandContext;

typedef struct AudioStreamManager { unsigned char _unknown_00[8]; void *music_stream0; void *music_work0; unsigned char _unknown_10[4]; void *music_stream1; void *music_work1; unsigned char _unknown_1c[4]; void *music_stream2; void *music_work2; unsigned char _unknown_28[4]; void *mono0; void *mono_work0; void *mono_buffer0; unsigned char _unknown_38[4]; void *mono1; void *mono_work1; void *mono_buffer1; unsigned char _unknown_48[4]; void *mono2; void *mono_work2; void *mono_buffer2; unsigned char _unknown_58[0x30]; int music_gain[3]; int mono_gain[3]; unsigned char _unknown_a0[8]; int fade_step; AudioStreamFade music_fades[3]; AudioStreamFade mono_fades[3]; unsigned char _unknown_f4[0x600]; unsigned char stereo_activity[3]; unsigned char mono_activity[3]; unsigned char _unknown_6fa[0x12]; int selected_track[3]; } AudioStreamManager;

typedef struct DialogueVoiceFifoRow { unsigned int opaque; int voice_number; } DialogueVoiceFifoRow;

typedef struct DialogueVoiceFifo { DialogueVoiceFifoRow rows[8]; int head; int tail; } DialogueVoiceFifo;

typedef struct DialogueVoiceOwner { unsigned char _unknown_00[0xD4]; DialogueVoiceFifo voice_fifo; Fighter *fighter; unsigned char _unknown_120[0x30]; int stream_slot; unsigned char _unknown_154[0x35]; unsigned char fighter_enabled; } DialogueVoiceOwner;

typedef struct DialogueVoiceRoot { unsigned char _unknown_00[0x56C]; int voice_row; } DialogueVoiceRoot;

typedef struct DialogueIndexedVoiceOwner { unsigned char _unknown_00[0x90]; int voice_row; } DialogueIndexedVoiceOwner;

typedef struct DialogueVoiceParticipant { unsigned char _unknown_00[0x44]; Fighter *fighter; unsigned char _unknown_48[0x10]; int stream_slot; } DialogueVoiceParticipant;

typedef struct GuideVoice { short fighter_id; unsigned char condition; unsigned char display_phase; unsigned char state; signed char selector; short member; short previous_member; short countdown; short request_word; } GuideVoice;

typedef struct GuideVoiceCueRow { unsigned char opaque; signed char event_members[6]; signed char idle_members_a[3]; signed char idle_members_b[3]; } GuideVoiceCueRow;

typedef struct CommandsHudAudioOwner { unsigned char _unknown_00; unsigned char fighter_id; unsigned char side; unsigned char _unknown_03; int command_index; void *command_record; Fighter *fighter; unsigned char command_marks[0x40]; unsigned char _unknown_50[0x38]; short display_countdown; short display_reload; unsigned char _unknown_8c[0x14]; void *tracking; GuideVoice *guide; } CommandsHudAudioOwner;

typedef struct CinematicAudioRow { short frame; signed char presentation; signed char cue; unsigned short damage; unsigned short chakra; } CinematicAudioRow;

typedef struct CinematicAudioDescriptor { int count; CinematicAudioRow *rows; } CinematicAudioDescriptor;

typedef struct CinematicAudioOwner { unsigned char _unknown_00[0x10]; CinematicAudioDescriptor *audio_rows; int next_audio_row; unsigned char _unknown_18[0x10]; short side; short fighter_b; short fighter_a; unsigned char _unknown_2e[0xA]; short character; short selector; short selector_copy; } CinematicAudioOwner;

typedef struct CinematicAudioScene { unsigned char _unknown_00[0x90]; int frame; } CinematicAudioScene;

typedef struct BattleSession {
 unsigned char flags;
 unsigned char _unknown_0001;
 unsigned short allowed_first_third;
 unsigned short allowed_second;
 unsigned short override_first_third;
 unsigned short override_second;
 short inner_state;
 unsigned short entry_type;
 unsigned char _unknown_000e[2];
 int inner_delay;
 void *camera_root;
 void *primary_owner;
 void *camera_helper;
 void *secondary_owner;
 void *side_services[2];
 void *clock;
 void *root;
 unsigned char _unknown_0034[4];
} BattleSession;

typedef StartMenuHost StartMenu;

typedef struct StartMenuSimpleDisplay { unsigned char _unknown_0000[0xc]; FrontEndModal *window; } StartMenuSimpleDisplay;

typedef struct StartMenuYesNo { int state; unsigned char _unknown_0004[8]; int accepted_result; unsigned char _unknown_0010[0x100]; FrontEndModal *window; UiPanel *body_panel; } StartMenuYesNo;

typedef struct CutinStageRecord { RegisteredActorReference reference; int state; int counter; float decay; unsigned char flags[3]; unsigned char _unknown_001b; } CutinStageRecord;

typedef struct CutinController {
 unsigned char _unknown_0000[0x3f0];
 void *first_sprite; // +0x3F0
 unsigned char _unknown_03f4[0x30];
 void *second_sprite; // +0x424
 unsigned char _unknown_0428[0x1c];
 float amplitude;
 float phase;
 float direction;
 unsigned char _unknown_0450[0x17c];
 float approach[3];
 unsigned char _unknown_05d8[0x18];
 CutinStageRecord side0;
 unsigned char _unknown_060c[0x1a4];
 CutinStageRecord side1;
 unsigned char _unknown_07cc[4];
 void *children[2][4];
 unsigned char _unknown_07f0[0x24];
 void *effect;
 int effect_index;
 unsigned int pending_commands[2];
 unsigned char staged;
 unsigned char _unknown_0825[7];
 int update_count;
 void *interface; // +0x830
 unsigned char _unknown_0834[0xc];
 unsigned char force_history;
} CutinController;

typedef struct CollectionSkillListRow {
    unsigned int opaque_word;
    unsigned char _unknown_0004[4];
    int skill;
    unsigned char _unknown_000C[4];
} CollectionSkillListRow;

typedef struct CollectionSkillViewer {
    unsigned char _unknown_0000[0xC];
    int playback_state;
    unsigned char _unknown_0010[8];
    int selection;
    int selected_skill;
    unsigned char _unknown_0020[0x198];
    CcsAnimationPlayer *secondary_player;
    unsigned char _unknown_01BC;
    unsigned char secondary_complete;
    unsigned char _unknown_01BE[0x16];
    CcsAnimationPlayer *selected_players[1];
    unsigned char _unknown_01D8[0x28];
    unsigned char selected_complete;
    unsigned char _unknown_0201[7];
    union { CollectionSkillListRow rows[1]; unsigned char _list_storage[0x200]; };
    CcsContainer *shared_container; // +0x408; row count remains unresolved
} CollectionSkillViewer;

typedef struct SupportCinematicAdmission {
    unsigned char support;
    unsigned char fighter;
    short admission;
} SupportCinematicAdmission;

typedef struct OverrideRequest { unsigned char value; unsigned char _unknown_01[3]; unsigned int mask; } OverrideRequest;

typedef struct AttachmentModelRow { int character_id; char *model_name; char *attachment_name; char *archive_path; } AttachmentModelRow;

typedef struct AllocatedArrayHeader { unsigned int element_size; unsigned int count; void *element_destructor; unsigned char _unknown_0c[4]; } AllocatedArrayHeader;

typedef struct BattleRootCombo { unsigned char suppressed; unsigned char active; unsigned char _unknown_02[2]; int side; int running_count; int latched_count; int hold_count; float opacity; int shake_x; int shake_y; int shake_count; unsigned char appearance_active; unsigned char _unknown_25[3]; float appearance_opacity; float appearance_scale; void *layer; unsigned char _unknown_34[4]; void *sprite; unsigned char animation_active; unsigned char _unknown_3d[3]; void *animation; } BattleRootCombo;

typedef struct BattleRootGauge { unsigned char suppressed; unsigned char forced; unsigned char _unknown_02[2]; void *context; unsigned char _unknown_08[4]; short x; short y; unsigned char placement; unsigned char _unknown_11[3]; float opacity; float echo_opacity; float echo_scale; unsigned char active; unsigned char _unknown_21[7]; short side; short duration; unsigned char _unknown_2c[3]; unsigned char label; unsigned char commands[6]; unsigned char _unknown_36[2]; unsigned char sprites[4][0xf8]; unsigned char _unknown_418[8]; unsigned char animation[0x120]; void *layer; unsigned char _unknown_544[0x30]; float ramp_fraction; short ramp_denominator; short ramp_count; unsigned char ordinary_path; unsigned char _unknown_57d[3]; } BattleRootGauge;

typedef struct BattleRootStock { unsigned char _unknown_00[8]; unsigned char sprites[3][0xf8]; unsigned char _unknown_2f0[4]; char *title; unsigned char *sequence; unsigned char _unknown_2fc[0x24]; } BattleRootStock;

typedef struct BattleRootMarker { unsigned char _unknown_00[8]; void *children[26]; } BattleRootMarker;

typedef struct BattleRootHistory { void *sprite; void *popup_head; unsigned char _unknown_08[0x48]; } BattleRootHistory;

typedef struct BattleSharedIcons { void *sprites[5]; void *layer; void *animation; void *alternate_layer; unsigned char _unknown_20[8]; } BattleSharedIcons;

typedef struct BattleNotice { void *layer; void *subordinate; void *sprites[2]; unsigned char _unknown_10[0x24]; } BattleNotice;

typedef struct BattlePresentationRoot { BattleRootCombo *combo; BattlePromptDisplay *prompts; BattleCommandStrip *command_strip; void *world_markers; BattleGameplayIcons *gameplay_icons; BattleSharedIcons *shared_icons; BattleRootHistory *history; BattleNotice *notice; unsigned char initialized; unsigned char callbacks_suppressed; unsigned char _unknown_22[0xe]; unsigned char controller[0x40]; } BattlePresentationRoot;

typedef struct NodeMethods { unsigned char _unknown_00[8]; void *destroy; void *start; void *update; void *second_phase; void *third_phase; } NodeMethods;

typedef struct FighterId004LateState { unsigned char _unknown_00[0xca0]; float attack_offset[4]; unsigned char _unknown_cb0[0x40]; float secondary_attack_offset[4]; } FighterId004LateState;

typedef struct FighterId018Lifecycle { unsigned char _unknown_00[0x4fa8]; unsigned char trail_flags; unsigned char _unknown_4fa9[3]; unsigned int query_result; PuppetMotion motion; unsigned char _unknown_5014[0x68]; unsigned short result; unsigned char _unknown_507e[2]; short animation_index; short synchronized_index; TimelineBlock timer; unsigned char _unknown_50a8[0x68]; void *model; void *scene; void *animation_lookup_first; unsigned char _unknown_511c[0x24c]; int animation_count; void *animation_names; void **animations; void *control; } FighterId018Lifecycle;

typedef struct FighterId059Lifecycle { unsigned char _unknown_00[0x57a0]; void *scene_array; unsigned char _unknown_57a4[0x1c]; float attack_offset[4]; unsigned char _unknown_57d0[0x14]; void *scene; } FighterId059Lifecycle;

typedef struct FighterId091Lifecycle { unsigned char _unknown_00[0x5aa8]; void *auxiliary_before_controller; void *wood_controller; void *auxiliary_after_controller; } FighterId091Lifecycle;

typedef struct WoodController { void *head; Fighter *fighter; unsigned char _unknown_0008[0x20]; void *vtable; } WoodController;

typedef struct LifecycleSceneRate { unsigned char _unknown_00[0x94]; short rate; } LifecycleSceneRate;

typedef struct TransportDescriptor { int count; unsigned char *data; int state; } TransportDescriptor;

typedef struct GzlistFileNode { struct GzlistFileNode *next; char name[32]; unsigned int decoded_size; } GzlistFileNode;

typedef struct GzlistDirectoryNode { struct GzlistDirectoryNode *sibling; char name[32]; GzlistFileNode *files; struct GzlistDirectoryNode *children; int capacity; void *directory_buffer; } GzlistDirectoryNode;

typedef struct FlistLocation { unsigned int lsn; unsigned int bytes; } FlistLocation;

typedef struct FlistCacheState { void *storage; int count; int capacity; int maximum_name_length; } FlistCacheState;

typedef struct DeviceFileHandle { void *callbacks; void *file; } DeviceFileHandle;

typedef struct DeviceRegistration { void *callbacks; char name[12]; } DeviceRegistration;

typedef struct RofsVolumeRecord { DeviceFileHandle *backing; unsigned char _unknown_0004[0x12]; char name[9]; unsigned char _unknown_001f[0x15]; } RofsVolumeRecord;

typedef struct RofsFileHandle { unsigned char _unknown_0000[0x1c]; RofsVolumeRecord *volume; unsigned char _unknown_0020[0x14]; short in_use; short operation; short state; unsigned char _unknown_003a[2]; } RofsFileHandle;

typedef struct AdxfHandle { unsigned char in_use; unsigned char state; unsigned char borrowed_stream; unsigned char stop_pending; void *stream; void *destination_adapter; int file_sectors; unsigned long long file_bytes; int position; int requested_start; int requested_sectors; int transferred_sectors; void *destination; int destination_bytes; unsigned int _unknown_0030; int archive_base; void *directory; char *pathname; int range_start; int range_sectors; } AdxfHandle;

typedef struct AfsExactMemberSizes { unsigned int first_offset_bytes; unsigned int member_bytes[1]; } AfsExactMemberSizes;

typedef struct AfsSectorMemberSizes { unsigned short first_offset_sectors; unsigned short member_sectors[1]; } AfsSectorMemberSizes;

typedef union AfsMemberSizes { AfsExactMemberSizes exact; AfsSectorMemberSizes sectors; } AfsMemberSizes;

typedef struct AfsPartitionMetadata { unsigned int _unknown_0000; unsigned int metadata_bytes; unsigned int member_count; unsigned short count16; unsigned char _unknown_000e; unsigned char exact_byte_mode; char pathname[0x100]; void *directory; int archive_base_sector; AfsMemberSizes sizes; } AfsPartitionMetadata;

typedef struct AfsParserState { int member_cursor; AdxfHandle *transport; int partition_id; int state; unsigned int _unknown_0010; void *input_buffer; int input_sectors; } AfsParserState;

typedef struct AfsMetadataAllocation { AfsPartitionMetadata *metadata; unsigned int capacity; } AfsMetadataAllocation;

typedef struct AfsManager { unsigned char _unknown_0000[0xf4]; AfsMetadataAllocation top_level[4]; AfsMetadataAllocation first_sound_child; unsigned char _unknown_011c[0x60]; AfsMetadataAllocation first_rpgvoice_child; unsigned char _unknown_0184[0x288]; AfsMetadataAllocation first_plvoice_child; unsigned char _unknown_0414[0x2e8]; int group_counts[4]; unsigned char _unknown_070c[0xc]; } AfsManager;

typedef struct CcsUngzip { CcsReader *source; CcsReader *destination; int method; unsigned int gzip_flags; unsigned int mtime; char *diagnostic_name; int format_status; int output_chunk_bytes; void *scratch; unsigned char *output_span; int output_used; unsigned int produced_bytes; char *class_name; int input_cursor; unsigned char *input_span; int input_span_bytes; unsigned int crc32; } CcsUngzip;

typedef struct BtlFieldOverrideCountdown {
 BtlSkillPlayback base;
 unsigned char _unknown_0ff0[0xca];
 unsigned char field_override_active;
 unsigned char _unknown_10bb[0x4d];
 int field_override_countdown;
} BtlFieldOverrideCountdown;

typedef struct PausePresentationEffectRecord {
 int state;
 unsigned int flags;
 unsigned char _unknown_0008[4];
 AwakeningPauseGate *controller;
} PausePresentationEffectRecord;

typedef struct ToneShadeRenderContext { unsigned char _unknown_0000[0x250]; ToneShadeRandomDestination *tone_destination; } ToneShadeRenderContext;

typedef struct SectorReadStatusView { unsigned char _unknown_0000[0x504]; unsigned char read_status; } SectorReadStatusView;

typedef BattleRootGauge BattlePromptDisplay;

typedef BattleRootStock BattleCommandStrip;

typedef BattleRootMarker BattleGameplayIcons;

typedef struct FlistDescriptor { char *pathname; int maximum_name_length; void *storage; int storage_bytes; } FlistDescriptor;

typedef struct DeviceCallbacks { void *pump; unsigned char _unknown_0004[0xc]; void *open; void *close; unsigned char _unknown_0018[0x48]; void *control; unsigned int _unknown_0064; } DeviceCallbacks;

typedef struct CardIconSystem { char header[4]; unsigned char _unknown_0004[0x100]; char first_icon_name[11]; unsigned char _unknown_010f[0x35]; char second_icon_name[11]; unsigned char _unknown_014f[0x35]; char third_icon_name[11]; unsigned char _unknown_018f[0x235]; } CardIconSystem;

typedef struct BattleCamera {
 unsigned char _unknown_0000[0x14];
 char *debug_name;
 unsigned char _unknown_0018[8];
 Fighter *fighters[2];
 unsigned char _unknown_0028[8];
 float eye[4];
 float angles[4];
 void *vtable;
 unsigned char _unknown_0054[0xc];
 unsigned char active;
 unsigned char hold;
 unsigned char snap;
 unsigned char _unknown_0063;
 int tracking_mode;
 float eye_coefficient_override;
 float target_coefficient_override;
 float eye_step_limit;
 float target_step_limit;
 unsigned char _unknown_0078[8];
 float target[4];
 float eye_offset[4];
 float distance;
 EngineBattleCamera *engine_camera;
 CameraOutputView *output;
 unsigned char _unknown_00ac[0xb4];
} BattleCamera;

typedef struct StageCameraRecord {
 float eye_decreasing;
 float eye_increasing_large;
 float eye_increasing_medium;
 float eye_increasing_small;
 float unknown_10;
 float target_same_section;
 float unknown_18;
 float target_large;
 float target_medium;
 float target_small;
 float min_distance;
 float max_distance;
 float target_upper;
 float target_lower;
 float edge_upper;
 float edge_lower;
 float eye_height_cap;
 float unknown_44;
 float eye_lateral_scale;
 float differing_section_elevation;
 float same_nonzero_section_elevation;
 float spread_control;
 float unknown_58;
 float unknown_5c;
} StageCameraRecord;

typedef struct MainBattleCamera {
 BattleCamera base;
 unsigned char dynamic_fov;
 unsigned char tracking_initial;
 unsigned char average_third_point;
 unsigned char _unknown_0163;
 int tracking_submode;
 unsigned char _unknown_0168[4];
 short tracking_counters[2];
 float desired_elevation;
 float elevation;
 float eye_coefficient;
 float target_coefficient;
 unsigned char _unknown_0180[0x14];
 StageCameraRecord *stage_record;
 StageCameraRecord *previous_stage_record;
 unsigned char _unknown_019c[4];
 float saved_tracking[2][4];
 unsigned char _unknown_01c0[0x10];
} MainBattleCamera;

typedef struct PresentationCameraRecord {
 unsigned char anchor_enabled[2];
 unsigned char supplied_initial[2];
 unsigned char initial_enabled[2];
 unsigned char offset_enabled[2];
 unsigned char snap;
 unsigned char _unknown_0009[3];
 unsigned int flags;
 int anchor_selectors[2];
 int eye_delay;
 int target_delay;
 unsigned int unknown_20;
 int eye_duration;
 int target_duration;
 unsigned int unknown_2c;
 unsigned char _unknown_0030[0x20];
 float initial[2][4];
 float offsets[2][4];
 float endpoints[2][4];
} PresentationCameraRecord;

typedef struct PresentationCamera {
 BattleCamera base;
 unsigned char initialize_motion;
 unsigned char snap_goals;
 unsigned char eye_snapshot_pending;
 unsigned char target_snapshot_pending;
 unsigned int flags;
 unsigned char _unknown_0168[8];
 float initial[2][4];
 float *anchors[2];
 unsigned char _unknown_0198[8];
 float offsets[2][4];
 float snapshots[2][4];
 float endpoints[2][4];
 float displacement[2][4];
 float step_lengths[2];
 int eye_delay;
 int target_delay;
 unsigned int unknown_230;
 int eye_duration;
 int target_duration;
 unsigned int unknown_23c;
 int eye_counter;
 int target_counter;
 unsigned char _unknown_0248[8];
} PresentationCamera;

typedef struct BattleCameraController {
 int side;
 int mode;
 int previous_mode;
 int preset;
 int previous_preset;
 int request;
 int previous_request;
 int pending_event;
 int previous_event;
 int discriminator;
 int counter_enabled;
 int counter;
 int ownership;
 int slot_count;
 int slot;
 int previous_slot;
 BattleCamera *slots[8];
 CameraRegistry *registry;
 float correction_angle;
} BattleCameraController;

typedef struct MainCameraFrame {
 Fighter *fighters[2];
 unsigned char _unknown_0008[8];
 float eye[4];
 float target[4];
 float spread_reference[4];
 float fighter_positions[2][4];
 float third_point[4];
 float background_vector[4];
 unsigned char _unknown_0080[0x10];
 float vertical_span;
 float frame_span;
 unsigned char _unknown_0098[0x1c];
 float fit_distance;
 float spread;
 unsigned char _unknown_00bc[4];
} MainCameraFrame;

typedef struct PuppetRecord {
    unsigned int result;
    short animation_index;
    short synchronized_index;
    TimelineBlock timeline;
    unsigned char _unknown_2c[0x44];
    void *attachment_scene;
    void *scene;
    CcsAnimationPlayer *playback;
    void **animations;
} PuppetRecord;

typedef struct PuppetMotion {
    float height;
    float width;
    float cached_position[3];
    unsigned int mode;
    float previous_x;
    float current_x;
    float target_x;
    float interpolation_x;
    float previous_z;
    float current_z;
    float target_z;
    float interpolation_z;
    unsigned char _unknown_38[4];
    float vertical_delta;
    float vertical_decay;
    float previous_y;
    unsigned char _unknown_48[0xc];
    float deformation_decay_source; // Chiyo clears this; nonzero writer is unresolved
    unsigned char _unknown_58[0xc];
} PuppetMotion;

typedef struct PuppetTrailDefinition {
    char attachment_names[4][30];
    unsigned short lifetime;
    short pool_count;
    short point_count;
    unsigned short extra_temporal_samples;
    float tension;
    unsigned char _unknown_84[4];
} PuppetTrailDefinition;

typedef struct PuppetTrailPoint {
    unsigned char projection_flags;
    unsigned char _unknown_01[3];
    unsigned int color;
    unsigned char _unknown_08[8];
    float position[4];
    float projected_position[4];
} PuppetTrailPoint;

typedef struct PuppetTrailSample {
    unsigned char flags; // bit 0 marks a temporal insertion
    unsigned char _unknown_01;
    short remaining_lifetime;
    float fade;
    struct PuppetTrailSample *newer;
    struct PuppetTrailSample *older;
    PuppetTrailPoint points[16];
} PuppetTrailSample;

typedef struct PuppetTrailNode {
    PuppetTrailDefinition *definition;
    Fighter *primary;
    CcsAnimationPlayer *playback;
    void *cached_attachments[4];
    PuppetTrailSample *pool;
    PuppetTrailSample *newest;
    PuppetTrailSample *oldest;
    float deformation_envelope;
    unsigned char _unknown_2c[4];
    float phase[4];
    float amplitude[4];
    float decay[4];
    short active_count;
    short pool_count;
    short point_count;
    unsigned char _unknown_66[2];
    float parameters[16];
    unsigned char _unknown_a8[0x28];
    struct PuppetTrailNode *next;
    unsigned char _unknown_d4[0xc];
} PuppetTrailNode;

typedef struct PuppetTrailHelper {
    int node_count;
    PuppetTrailNode *head;
} PuppetTrailHelper;

typedef struct KankuroPuppetState {
    unsigned char _unknown_0000[0x4fec];
    unsigned char trail_flags;
    unsigned char _unknown_4fed[3];
    unsigned int query_result0;
    PuppetMotion motion0;
    void *animation_lookup0[127];
    unsigned int query_result1;
    PuppetMotion motion1;
    void *animation_lookup1[127];
    unsigned char _unknown_54b8[0x68];
    PuppetRecord records[2];
    PuppetTrailHelper *helpers[2];
} KankuroPuppetState;

typedef struct ChiyoPuppetState {
    unsigned char _unknown_0000[0x56b4];
    unsigned char trail_flags;
    unsigned char _unknown_56b5[3];
    unsigned int query_result0;
    PuppetMotion motion0;
    void *animation_lookup0[139];
    unsigned int query_result1;
    PuppetMotion motion1;
    void *animation_lookup1[139];
    unsigned char _unknown_5be0[0x10];
    PuppetRecord records[2];
    void *material;
    void *palettes[2];
    PuppetTrailHelper *helper;
} ChiyoPuppetState;

typedef struct SasoriPuppetState {
    unsigned char _unknown_0000[0x4df0];
    unsigned char trail_flags;
    unsigned char _unknown_4df1[3];
    unsigned int query_result;
    PuppetMotion motion;
    unsigned char _unknown_4e5c[4];
    unsigned int result;
    short animation_index;
    short synchronized_index;
    TimelineBlock timeline;
    unsigned char _unknown_4e8c[0x64];
    void *scene;
    CcsAnimationPlayer *playback;
    void *animation_lookup_first;
    void *animation_lookup_remaining[119];
    int animation_count;
    void *animation_names;
    void **animations;
    void *material;
    void *palette;
    PuppetTrailHelper *helper;
    unsigned int second_state;
    int second_selector;
    void *second_animations[7];
    CcsAnimationPlayer *second_playback;
    unsigned char _unknown_5118[8];
    float snapshot[4];
    void *generator_materials[2];
} SasoriPuppetState;

typedef struct SasoriBoneGeometryRecord {
    void *bone;
    void *owned_geometry;
    void *saved_geometry;
} SasoriBoneGeometryRecord;

typedef struct SasoriVariant76Geometry {
    unsigned char _unknown_0000[0x4d70];
    SasoriBoneGeometryRecord bones[17];
    unsigned char _unknown_4e3c[0xcc];
    unsigned char constructed_records[2][0x1c];
} SasoriVariant76Geometry;

typedef struct SasoriVariant75Materials {
    unsigned char _unknown_0000[0x5648];
    void *materials[3];
} SasoriVariant75Materials;

typedef struct SasoriGeneratorState {
    unsigned char _unknown_0000[0x1ec];
    short emitter_lifetime;
    unsigned char _unknown_01ee[2];
    unsigned char _unknown_01f0[4];
    short particle_lifetime;
    unsigned char _unknown_01f6[2];
    unsigned char _unknown_01f8[8];
    float emission;
    unsigned char _unknown_0204[4];
    float variation;
    unsigned char _unknown_020c[8];
    short fade_start;
    short fade_step;
    unsigned char _unknown_0218[0x4c];
    unsigned char position_enabled;
    unsigned char _unknown_0265[0xb];
    float position[4];
} SasoriGeneratorState;

typedef struct CharacterAnimationRow { short animation_slot; short duration; short start_frame; unsigned short rate; union { unsigned char motion_flags[2]; unsigned short motion_flag_mask; }; short motion_event; float planar_speed; float vertical_speed; float motion_decay; float motion_multiplier; unsigned int bank1_flags; short bank1_start; short bank1_end; float bank1_radius; char *skeleton_object_name; float bank1_offset_x; union { float bank2_attack_offset; float bank1_offset_z; }; unsigned int bank2_flags; short bank2_start; short bank2_end; float bank2_radius; char *bank2_skeleton_object_name; float bank2_offset_x; float bank2_offset_z; } CharacterAnimationRow;

typedef struct EngineBattleCamera { unsigned char _unknown_0000[0xc]; float field_of_view; float view_matrix[16]; } EngineBattleCamera;

typedef struct CameraOutputView { unsigned char _unknown_0000[0x3c]; void *view_destination; } CameraOutputView;

typedef struct ParticleGeneratorParameters {
    unsigned char emission_geometry; // +0x0
    unsigned char velocity_flags; // +0x1
    unsigned char _pad_0002[0x2];
    short emitter_lifetime; // +0x4
    unsigned char _pad_0006[0x6];
    short particle_lifetime; // +0xC
    unsigned char _pad_000e[0x2];
    short base_angles[2]; // +0x10
    float speed; // +0x14
    float emission_rate; // +0x18
    unsigned char _pad_001c[0x4];
    float lifetime_variation; // +0x20
    float speed_variation; // +0x24
    unsigned short angle_spread[2]; // +0x28
    short fade_in; // +0x2C
    short fade_out; // +0x2E
    unsigned char _pad_0030[0x8];
} ParticleGeneratorParameters;

typedef struct ParticleForceDescriptor {
    unsigned char flags; // +0x0
    unsigned char radius_mode; // +0x1
    unsigned char key; // +0x2
    unsigned char _pad_0003[0x1];
    short angle; // +0x4
    unsigned char _pad_0006[0x2];
    float radius; // +0x8
    unsigned char _pad_000c[0x4];
    float values[4]; // +0x10
} ParticleForceDescriptor;

typedef struct ParticleHistorySnapshot {
    float position[4]; // +0x0
    float rotation[4]; // +0x10
    float base_scale[4]; // +0x20
    float color[4]; // +0x30
} ParticleHistorySnapshot;

typedef struct ParticleResourceChoice {
    void * resource; // +0x0
    void * auxiliary_a; // +0x4
    void * auxiliary_b; // +0x8
    void * auxiliary_c; // +0xC
    void * auxiliary_d; // +0x10
    int selector; // +0x14
    unsigned int playback_configuration; // +0x18
    unsigned char option; // +0x1C
    unsigned char _pad_001d[0x3];
    struct ParticleResourceChoice * next; // +0x20
    int index; // +0x24
} ParticleResourceChoice;

typedef struct ParticleVisual {
    void * vtable; // +0x0
    int selector; // +0x4
    void * resource; // +0x8
    int frame; // +0xC
    float position[4]; // +0x10
    float rotation[4]; // +0x20
    float base_scale[4]; // +0x30
    float composed_scale[4]; // +0x40
    float color[4]; // +0x50
    float translation[4]; // +0x60
    unsigned char playback_mode; // +0x70
    unsigned char _pad_0071[0x3];
    float alpha_scale; // +0x74
    void * resource_key; // +0x78
    unsigned char render_option; // +0x7C
    unsigned char _pad_007d[0x3];
    unsigned char active; // +0x80
    unsigned char suppressed; // +0x81
    unsigned char _pad_0082[0x2];
    int reset_age; // +0x84
    int age; // +0x88
    unsigned char _pad_008c[0x4];
    float velocity[4]; // +0x90
} ParticleVisual;

typedef struct ParticleElement {
    void * vtable; // +0x0
    ParticleVisual * visual; // +0x4
    unsigned char _pad_0008[0x8];
    float displacement[4]; // +0x10
    float rotation[4]; // +0x20
    float scale[4]; // +0x30
    float correction[4]; // +0x40
    float color[4]; // +0x50
    float origin_delta[4]; // +0x60; primary origin minus spawned visual position
    float angular_state[3]; // +0x70
    unsigned char scale_direction; // +0x7C
    unsigned char skip_draw_once; // +0x7D
    unsigned char fade_state; // +0x7E
    unsigned char _pad_007f[0x1];
    int hold; // +0x80
    ParticleHistorySnapshot * history; // +0x84
    int history_capacity; // +0x88
    int history_used; // +0x8C
    float history_distance; // +0x90
    unsigned char history_option; // +0x94
    unsigned char _pad_0095[0xb];
} ParticleElement;

typedef struct ParticleForceField {
    void * vtable; // +0x0
    unsigned char enabled; // +0x4
    unsigned char direct_selection; // +0x5
    unsigned char _pad_0006[0xa];
    float offset[4]; // +0x10
    float manager_anchor[4]; // +0x20
    float direct_values[4]; // +0x30
    unsigned char _pad_0040[0x10];
    ParticleForceDescriptor descriptor; // +0x50
    float center[4]; // +0x70
    struct ParticleForceField * next; // +0x80
    struct ParticleForceField * previous; // +0x84
    int slot; // +0x88
    unsigned char _pad_008c[0x4];
} ParticleForceField;

typedef struct ParticleEmitter {
    void * vtable; // +0x0
    int age; // +0x4
    unsigned char state; // +0x8
    unsigned char _pad_0009[0x3];
    ParticleForceField * fields; // +0xC
    ParticleElement * particles; // +0x10
    int capacity; // +0x14
    int constructed_count; // +0x18
    int cursor; // +0x1C
    int live_count; // +0x20
    float emission_accumulator; // +0x24
    unsigned char _pad_0028[0x4];
    int emission_delay; // +0x2C
    int delay_counter; // +0x30
    unsigned char emission_enabled; // +0x34
    unsigned char emission_stopped; // +0x35
    unsigned char repeat_enabled; // +0x36
    unsigned char distance_enabled; // +0x37
    ParticleResourceChoice * resources; // +0x38
    int resource_count; // +0x3C
    unsigned char _pad_0040[0x8];
    int identifier; // +0x48
    struct ParticleEmitter * previous; // +0x4C
    struct ParticleEmitter * next; // +0x50
    struct ParticleOriginLink origin_links[2]; // +0x54
    int field_count; // +0x64
    unsigned char _pad_0068[0x8];
    float basis[16]; // +0x70
    float primary_origin[4]; // +0xB0
    float previous_primary_origin[4]; // +0xC0
    unsigned char _pad_00d0[0x20];
    float secondary_origin[4]; // +0xF0
    float previous_secondary_origin[4]; // +0x100
    float primary_offset[4]; // +0x110
    float secondary_offset[4]; // +0x120
    float resolved_primary_origin[4]; // +0x130
    float resolved_secondary_origin[4]; // +0x140
    float scale[4]; // +0x150
    float color[4]; // +0x160
    float manager_position[4]; // +0x170; refreshed when the manager anchor changes
    float alpha_scale; // +0x180
    float random_alpha_bound; // +0x184
    float distance_min; // +0x188
    float distance_max; // +0x18C
    float alpha_inner; // +0x190
    float alpha_outer; // +0x194
    unsigned char fade_state; // +0x198
    unsigned char playback_mode; // +0x199
    unsigned char emission_mode; // +0x19A
    unsigned char _pad_019b[0x5];
    float translation_product[4]; // +0x1A0; manager-position product, with origin-motion adjustment
    float scale_product[4]; // +0x1B0
    float color_product[4]; // +0x1C0
    int initial_frame; // +0x1D0; -1 leaves the visual frame unchanged
    void * custom_spawn; // +0x1D4
    void * draw_environment; // +0x1D8
    int history_capacity; // +0x1DC
    float history_distance; // +0x1E0
    unsigned char history_option; // +0x1E4
    unsigned char primary_origin_changed; // +0x1E5
    unsigned char _pad_01e6[2];
    ParticleGeneratorParameters parameters; // +0x1E8
} ParticleEmitter;

typedef struct BattleParticleGenerator {
    ParticleEmitter base; // +0x0
    void * resources; // +0x220
    int resource_count; // +0x224
    short stage_surface_variant; // +0x228; independent stage/position column +0x22
    unsigned char _pad_022a[0x2];
    int deferred_stop; // +0x22C
    void * requested_environment; // +0x230
    ParticleForceField * cached_fields[4]; // +0x234
    ParticleForceField * external_fields[4]; // +0x244
    int external_field_indices[4]; // +0x254
    unsigned char origin_updated; // +0x264
    unsigned char _pad_0265[0xb];
    float primary_position[4]; // +0x270
} BattleParticleGenerator;

typedef struct ParticleManager {
    void * vtable; // +0x0
    unsigned char _pad_0004[0xc];
    float position[4]; // +0x10
    float scale[4]; // +0x20
    float color[4]; // +0x30
    float reference[4]; // +0x40
    unsigned char anchor_changed; // +0x50
    unsigned char update_enabled; // +0x51
    unsigned char draw_enabled; // +0x52
    unsigned char _pad_0053[0x1];
    int capacity_budget; // +0x54
    int emitter_count; // +0x58
    ParticleEmitter * emitters; // +0x5C
    int next_identifier; // +0x60
    int reserved_capacity; // +0x64
    unsigned char _pad_0068[0x8];
} ParticleManager;

typedef struct ModelVuDescriptor { unsigned int gif_registers; unsigned int instruction_entry; void *upload_stream; unsigned int upload_bytes; } ModelVuDescriptor;

typedef struct ModelDrawBase { unsigned char _unknown_0000[0x124]; unsigned char clipping_enabled; unsigned char _unknown_0125[0xb]; unsigned long long tex1_sampling; float direction_offset; } ModelDrawBase;

typedef struct CcsModelInstance { CcsRecord *record; void *bounds; void *parts; float uniform_scale; void *children; unsigned short child_count; unsigned short part_count; unsigned int runtime_flags; unsigned int ownership_flags; short material_count; unsigned char draw_state; unsigned char _unknown_0023; unsigned int test_state; float depth_offset; unsigned char _unknown_002c[4]; unsigned long long blend_state; struct CcsRenderMaterial **materials; unsigned char _unknown_003c[4]; struct CcsExtraPassOwner *extra_pass_owner; } CcsModelInstance;

typedef struct CcsModelDrawContext { unsigned char _unknown_0000[0x80]; float device_matrix[16]; unsigned char _unknown_00c0[0x4c]; float camera_depth; float *model_matrix; float alpha; float material_alpha; float strip_sign; unsigned long long primitive_state; CcsTextureChunk *texture; unsigned char _unknown_012c[4]; unsigned long long blend_state; unsigned long long test_state; unsigned long long tex1_sampling; unsigned char _unknown_0148[0x78]; void *workspace_cursor; unsigned char _unknown_01c4[0x2c]; unsigned short base_selector; unsigned char _unknown_01f2[2]; ModelDrawBase *draw_base; void *renderer; void *draw_environment; struct CcsMorpherRuntime *morph_controller; CcsModelInstance *instance; unsigned char draw_state; unsigned char _unknown_0209[3]; unsigned int runtime_flags; float uniform_scale; unsigned int fog_value; unsigned int fog_color; struct CcsRuntimeModelPart *part; unsigned short part_index; unsigned short ownership_flags; unsigned char bounds_classification; unsigned char _unknown_0225; unsigned short packet_bytes; void *packet; unsigned int vertex_count; void *positions; void *vectors; unsigned int *uv_words; unsigned int *auxiliary_attributes; unsigned char *strip_controls; void *indexes; void *extra_pass_descriptor; struct CcsDescriptorPassOwner *descriptor_pass_owner; struct CcsContext2Descriptor *context2_owner; struct CcsRenderMaterial *material; unsigned char _unknown_0258[0xc]; unsigned char direction_selector; unsigned char geometry_selector; unsigned char uv_modified; unsigned char _unknown_0267[0x19]; } CcsModelDrawContext;

typedef struct CcsWeightedVertex { short *influences; unsigned int *attributes; unsigned int *uv; unsigned int influence_count; } CcsWeightedVertex;

typedef struct CcsWeightedPartBuffer { void *output; unsigned int output_bytes; CcsWeightedVertex *vertices; short *influences; unsigned int *attributes; unsigned int *uv; int vertex_count; int influence_count; float position_scale; unsigned char read_failed; } CcsWeightedPartBuffer;

typedef struct CcsRigidPartBuffer { void *output; unsigned int output_bytes; short *positions; unsigned int *attributes; unsigned int *uv; int vertex_count; float position_scale; unsigned char read_failed; unsigned char _unknown_001d[3]; unsigned int palette_selector; } CcsRigidPartBuffer;

typedef struct PuppetAnimationNameRate { char *name; short rate; unsigned char _unknown_06[2]; } PuppetAnimationNameRate;

typedef struct ParticleOriginLink {
    void *target;
    unsigned char mode;
    unsigned char _pad_0005[3];
} ParticleOriginLink;

typedef struct BattleHudFrame { struct BattleTopPanel *parent; void *disc_sprite; void *frame_sprite; float speed; float phases[3]; } BattleHudFrame;

typedef struct BattleHudHp { struct BattleTopPanel *parent; void *sprite; float current; float trailing; int delay; unsigned char _unknown_14[8]; float maximum; float ratio; unsigned char tint; unsigned char _unknown_25[3]; } BattleHudHp;

typedef struct BattleHudName { struct BattleTopPanel *parent; void *sprite; int character_id; } BattleHudName;

typedef struct BattleHudSupport { int side; Fighter *fighter; unsigned char mode; unsigned char character_id; unsigned char visible; unsigned char category; float fill; float previous_fill; unsigned char _unknown_14[4]; void *gauge_sprite; void *glyph_sprite; void *frame_sprite; float pulse_scale; float pulse_alpha; } BattleHudSupport;

typedef struct BattleHudClockDigit { unsigned char value; unsigned char _unknown_01[3]; float scale; } BattleHudClockDigit;

typedef struct BattleHudClock { BattleHudClockDigit digits[2]; void *sprite; void *context; void *texture; int current; int previous; int change_count; float offset_y; float show_velocity; float hide_velocity; unsigned char hidden; unsigned char _unknown_35[3]; int hide_state; int show_state; int transition; } BattleHudClock;

typedef struct BattleHudRenderContext { struct BattleHudRenderContext *next; unsigned short id; unsigned char special_processing; unsigned char owns_renderer; union { unsigned int allocation_list_selector; RenderPacketList packet_list; }; RenderOrderingTree ordering; unsigned char _unknown_30[0x0c]; void *renderer; } BattleHudRenderContext;

typedef struct BattleHudCellKey { short character_id; unsigned char cell; unsigned char _unknown_03; } BattleHudCellKey;

typedef struct BattleHudRectangle { short u; short v; short width; short height; } BattleHudRectangle;

typedef struct BattleHudComboStyle { unsigned int color; float scale; int threshold; } BattleHudComboStyle;

typedef struct BattleHudStatusGlyph { unsigned char _unknown_00[4]; int side; unsigned char _unknown_08[0x14]; short x; short y; short offset_x; short offset_y; unsigned char _unknown_24[0x14]; } BattleHudStatusGlyph;

// Partial view of the 0x440-byte record returned by btl_record_lookup; only camera exit control is established here.
typedef struct BtlCameraExitRecordPrefix { unsigned char _unknown_00; unsigned char camera_reset_on_exit; } BtlCameraExitRecordPrefix;

typedef struct AfsArchiveHeader {
    char magic[4]; // AFS followed by NUL
    unsigned int member_count; // Little-endian 32-bit count; 8-byte header
} AfsArchiveHeader;

typedef struct AfsMemberEntry {
    unsigned int offset; // Little-endian byte offset relative to owning archive start
    unsigned int size; // Little-endian byte size; 8-byte table row
} AfsMemberEntry;

typedef struct AfsFilenameDirectoryLocation {
    unsigned int offset; // Little-endian byte offset relative to owning archive start
    unsigned int length; // Little-endian byte length; 8-byte pair after member table
} AfsFilenameDirectoryLocation;

typedef struct AfsFilenameDirectoryEntry {
    char filename[32];
    unsigned char _unknown_0020[0x10]; // Unassigned tail; complete row is 0x30 bytes
} AfsFilenameDirectoryEntry;

typedef struct CcsExtraPassOwner { unsigned long long blend_state; float width_multiplier; unsigned int color; unsigned int enabled; unsigned char _unknown_0014[4]; } CcsExtraPassOwner;

typedef struct CcsMorphSource { CcsModelInstance *model; float weight; } CcsMorphSource;

typedef struct CcsRuntimeModelPart { void *material; unsigned int vertex_count; unsigned int ownership_flags; unsigned short packet_bytes; unsigned char _unknown_000e[2]; void *packet; short *positions; unsigned int *attributes; unsigned int *uv_words; unsigned int *auxiliary_attributes; unsigned char *strip_controls; unsigned int influence_count; unsigned char _unknown_002c[4]; void *geometry; void *projection_geometry; unsigned int projection_geometry_size; unsigned char _unknown_003c[4]; } CcsRuntimeModelPart;

typedef struct CcsTransform { float position[3]; unsigned char _unknown_000c[4]; float rotation[3]; unsigned char _unknown_001c[4]; float scale[3]; unsigned char _unknown_002c[4]; } CcsTransform;

typedef struct CcsGeometryProperty { unsigned char selector; unsigned char element_type; unsigned char flags; unsigned char _unknown_0003; unsigned int count; unsigned char _unknown_0008[4]; unsigned int byte_length; void *payload; } CcsGeometryProperty;

typedef struct CcsPropertyGeometry { unsigned short kind; unsigned char _unknown_0002[2]; void *vtable; unsigned char highest_bone_index; unsigned char _unknown_0009[3]; unsigned int index_count; unsigned short *indexes; signed char *vectors; unsigned char *strip_controls; unsigned int rigid_count; unsigned int run_count; unsigned short *bone_runs; short *rigid_positions; unsigned int weighted_vertex_count; unsigned int influence_count; short *influences; CcsExtraPassOwner *extra_pass_owner; } CcsPropertyGeometry;

typedef struct CcsPropertyGeometryInstance { CcsPropertyGeometry *source; void *vtable; } CcsPropertyGeometryInstance;

typedef struct CcsPackedGeometry { unsigned short kind; unsigned char _unknown_0002[2]; void *vtable; void *packet; unsigned int packet_qwords; } CcsPackedGeometry;

// Partial owner prefix; full object size is not established.
typedef struct ParticleStandaloneOwner {
    void *controller; // +0x0
    ParticleManager *manager; // +0x4
} ParticleStandaloneOwner;

typedef struct SessionOutcomes { int side1; int side2; int draws; int other; int streak_count; int streak_side; } SessionOutcomes;

typedef struct BattleCountdown { unsigned char flags; unsigned char _unknown_01[3]; int remaining; int elapsed; int snapshot_0c; int snapshot_10; int limit; int reset_sentinel; int delta; } BattleCountdown;

typedef struct BattleConditionDefinition { unsigned char _unknown_00[0x18]; signed char count; unsigned char _unknown_19; short ids[4]; unsigned char _unknown_22[2]; unsigned int presentation_payloads[4]; unsigned char _unknown_34[0x18]; } BattleConditionDefinition;

typedef struct EncounterSequenceDefinition { unsigned char _unknown_00[4]; void *records /* contiguous three-byte rows */; short limit; } EncounterSequenceDefinition;

typedef struct EncounterFlow { int state; int ordinal; int limit; int elapsed; int ranking_row; int type; BattleConditionDefinition *conditions; void *sequence_data; unsigned char _unknown_20[4]; void *transition; unsigned char _unknown_28[4]; void *result_helper; EncounterSequenceDefinition *definition; RngShuffledIds *selection_table; } EncounterFlow;

typedef struct BattleVictoryRequest { int state; unsigned char _unknown_04[0xc]; int arguments_first[4]; unsigned char _unknown_20[4]; int arguments_last[2]; unsigned char requested; } BattleVictoryRequest;

typedef struct BattleSelectionTransition { int state; unsigned char _unknown_04[8]; int first; int second; unsigned char requested; } BattleSelectionTransition;

typedef struct MovieDescriptor { char *filename; unsigned int flags; int subtitles_enabled; int x; int y; int width; int height; int early_frame; int early_duration; int late_frame; int late_duration; } MovieDescriptor;

typedef struct MovieSubtitleRow { int start_frame; int end_frame; char *text; } MovieSubtitleRow;

typedef struct MoviePlaybackContext { MovieSubtitleRow *subtitle; int movie_id; int subtitle_alpha; unsigned char subtitle_fade; unsigned char _unknown_0d[3]; unsigned int flags; unsigned char subtitle_visible; unsigned char _unknown_15[3]; MovieDescriptor *descriptor; unsigned char early_transition; unsigned char late_transition; unsigned char wait_transition; unsigned char subtitles_finished; unsigned char _unknown_20[8]; } MoviePlaybackContext;

typedef struct MovieDiscStream { unsigned int remaining_bytes; unsigned int start_lsn; unsigned int file_size; unsigned char _unknown_0c[0x28]; } MovieDiscStream;

typedef struct MpegMoviePlayer { unsigned int saved_display_divisor; unsigned char _unknown_04[0x30]; unsigned char stop_requested; unsigned char pause_requested; unsigned char _unknown_36[0xa]; MovieDiscStream disc_stream; } MpegMoviePlayer;

typedef struct CriStream { unsigned char active; unsigned char state; unsigned char _unknown_02[0xa]; void *driver; unsigned char _unknown_10[0x62]; unsigned char mode; } CriStream;

typedef struct AdxV4History { unsigned char predictor1_be[2]; unsigned char predictor2_be[2]; } AdxV4History;

typedef struct AdxV4LoopBlock { unsigned char padding_be[2]; unsigned char marker_be[2]; unsigned char count_type_be[4]; unsigned char start_sample_be[4]; unsigned char start_offset_be[4]; unsigned char end_sample_be[4]; unsigned char end_offset_be[4]; } AdxV4LoopBlock;

typedef struct CaptureAttackPayload { unsigned int flags; unsigned char _unknown_0004[2]; short approach_duration; } CaptureAttackPayload;

typedef struct TsunadeCaptureMode { unsigned char _unknown_0000[0x5944]; unsigned char mode; } TsunadeCaptureMode;

typedef struct ChojiCaptureMode { unsigned char _unknown_0000[0x6238]; unsigned char mode; } ChojiCaptureMode;

typedef struct NarutoNineTailsCaptureScene { unsigned char _unknown_0000[0x582C]; void *auxiliary_scene; CcsAnimationDescriptor *synchronized_animation; } NarutoNineTailsCaptureScene;

typedef struct CcsCompositionInstance { float world_matrix[16]; float local_matrix[16]; void *parent; unsigned char _unknown_0084[9]; unsigned char matrix_dirty; unsigned short type_tag; CcsRecord *source_record; struct AttachmentManager *attachments; void **children; unsigned short child_count; unsigned char ownership_flags; unsigned char _unknown_009f; } CcsCompositionInstance;

typedef struct CcsPackedInfluence { short position[3]; unsigned short control; } CcsPackedInfluence;

typedef struct CcsBoneRun { unsigned short bone_index; unsigned short run_count; } CcsBoneRun;

typedef struct ModelVuWeightedHeader {
    unsigned int vertex_count_and_flags; // X: vertex_count + 0x8000
    unsigned int logical_vertex_end; // Y: 4 * vertex_count + 1
    unsigned int first_batch_marker; // Z: 0x8000 in the first weighted batch, zero thereafter
    unsigned int _unknown_w; // Producer writes 3 * influence_count + 1; consumer meaning is not established
} ModelVuWeightedHeader;

typedef struct ModelVuWeightedControl {
    unsigned int scaled_weight; // X: unsigned 16-bit source expanded into a 32-bit VU lane
    unsigned int palette_address; // Y: unsigned 16-bit source expanded into a 32-bit VU lane
    unsigned int list_count; // Z: first influence carries the narrowed list count, later influences carry 1
    unsigned int _unknown_w; // V3 unpack does not establish an independent W contract
} ModelVuWeightedControl;

typedef struct ModelVuWeightedUv {
    unsigned int u; // X: masked source halfword expanded into a 32-bit VU lane
    unsigned int v; // Y: masked source halfword expanded into a 32-bit VU lane
    unsigned int _unknown_z;
    unsigned int _unknown_w;
} ModelVuWeightedUv;

typedef struct ModelVuWeightedAttribute {
    int direction_x; // X: sign-extended source byte
    int direction_y; // Y: sign-extended source byte
    int direction_z; // Z: sign-extended source byte
    int strip_control; // W: sign-extended source byte; selected control semantics are proved for 0, 1 and 2
} ModelVuWeightedAttribute;

typedef struct ModelVuWeightedPosition {
    float x;
    float y;
    float z;
    unsigned int _unknown_w; // V3 unpack does not establish an independent W contract
} ModelVuWeightedPosition;

typedef struct UltimateJutsuHitRow { short frame; signed char popup; signed char sound; short damage_fraction; short chakra_fraction; } UltimateJutsuHitRow;

typedef struct UltimateJutsuHitDescriptor { int count; UltimateJutsuHitRow *rows; } UltimateJutsuHitDescriptor;

typedef struct UltimateJutsuSkillPlay { unsigned int stream_identifier; CcsContainer *container; char *main_path; CcsContainer *main_container; UltimateJutsuHitDescriptor *hits; int next_hit; unsigned char _unknown_0018[8]; float damage_dealt; unsigned char _unknown_0024[4]; short attacker_side; short side_ids[2]; unsigned short appearance_flags[2]; unsigned char _unknown_0032[4]; short attacker_id; short defender_id; short selected_skill; short skill; unsigned char _unknown_003E[0x42]; void *optional_body; unsigned char _unknown_0084[0xC]; struct { CcsScenePlayTarget *target; CcsModelInstance *replacement; void *original; } bone_replacements[17]; unsigned char _unknown_015C[0xE]; short request_ordinal; unsigned char _unknown_016C[0x154]; struct { unsigned char _unknown_0000[0x14]; short active; unsigned char _unknown_0016[0xE]; } popups[2]; } UltimateJutsuSkillPlay;

typedef struct UltimateJutsuPresentation { int state; int countdown; AwakeningPauseGate *controller; struct UltimateJutsuPresentationResources *resources; } UltimateJutsuPresentation;

typedef struct ContestVtable { void *class_info; void *reserved; void *update; void *render; } ContestVtable;

typedef struct ContestTimingNote { unsigned char launched; unsigned char _unknown_01; short result; short step; unsigned char _unknown_06[2]; float advance_countdown; short step_interval; unsigned char _unknown_0e[0x22]; } ContestTimingNote;

typedef struct CaptureModelLookupNode { unsigned char _unknown_0000[0x94]; void *nested_type100; } CaptureModelLookupNode;

typedef struct FighterCaptureVtable { unsigned char _unknown_0000[0x1C]; void *ai_update; void *pre_attachment; } FighterCaptureVtable;

typedef struct CharacterCaptureCallbacks { void *channel1; void *channel2; void *channel3; void *hit_response; void *channel5; void *channel6; void *channel7; } CharacterCaptureCallbacks;

typedef struct GuySubstitutionState { unsigned char _unknown_0000[0x69A8]; signed char loop_entry_count; unsigned char _unknown_69A9[7]; signed char chain_count; signed char effect_mode; unsigned char _unknown_69B2[2]; struct CcsExtraPassDescriptor *extra_pass_descriptor; } GuySubstitutionState;

typedef struct HirukoSubstitutionState { unsigned char _unknown_0000[0x4E3E]; short chain_count; } HirukoSubstitutionState;

typedef struct KurenaiSubstitutionState { unsigned char _unknown_0000[0x5626]; short previous_awakened_marker; } KurenaiSubstitutionState;

typedef struct CcsHitHeader { int resource_index; int model_index; unsigned short batch_count; unsigned char _unknown_000a[2]; int total_vertices; } CcsHitHeader;

typedef struct SurfaceEffectRow { unsigned int animation_id; unsigned int kind_mask; unsigned int contact_mask; unsigned int code_mask; } SurfaceEffectRow;

typedef struct SurfaceEffectSourceRow { char *animation_name; unsigned int kind_mask; unsigned int contact_mask; unsigned int code_mask; } SurfaceEffectSourceRow;

typedef struct SurfaceEffectDescriptor { char *resource_name; SurfaceEffectSourceRow *rows; int row_count; } SurfaceEffectDescriptor;

typedef struct SurfaceEffectManagerView { unsigned char _unknown_0000[0x2F0]; SurfaceEffectRow first_surface_row; unsigned char _unknown_0300[0xF0]; int surface_row_count; unsigned char _unknown_03f4[0x2D60]; unsigned int polygon_code; } SurfaceEffectManagerView;

typedef struct SurfaceEffectScratch { unsigned char _unknown_0000[0x10]; float saved_position[4]; unsigned char _unknown_0020[0xB8]; unsigned int saved_attributes; unsigned char _unknown_00dc[4]; } SurfaceEffectScratch;

typedef struct EffectWashActivation { unsigned char _unknown_0000[0x40]; unsigned char active; } EffectWashActivation;

typedef struct EffectLeakChakraActivation { unsigned char _unknown_0000[0x5C]; unsigned char active; } EffectLeakChakraActivation;

typedef struct AuxiliaryContactPositionView { unsigned char _unknown_0000[0xBB0]; float position[4]; unsigned char _unknown_0bc0[0x90]; unsigned int polygon_code; } AuxiliaryContactPositionView;

typedef struct AuxiliaryHandleView { unsigned char _unknown_0000[0xBB8]; void *animation_handle; } AuxiliaryHandleView;

typedef struct AuxiliaryParameterView { unsigned char _unknown_0000[0xBB0]; unsigned char flag; unsigned char _unknown_0bb1[3]; int parameter; unsigned char secondary_flag; } AuxiliaryParameterView;

typedef struct AuxiliaryMidpointView { unsigned char _unknown_0000[0xB10]; float previous_position[4]; unsigned char _unknown_0b20[0x90]; float saved_position[4]; unsigned char _unknown_0bc0[0x180]; float midpoint_source[4]; } AuxiliaryMidpointView;

typedef struct AuxiliaryCodeCacheView { unsigned char _unknown_0000[0xBB0]; float position[4]; unsigned char _unknown_0bc0[8]; unsigned int polygon_code; } AuxiliaryCodeCacheView;

typedef struct SurfaceCallbackOwner { unsigned char _unknown_0000[0x64]; Fighter *fighter; } SurfaceCallbackOwner;

typedef struct UltimateJutsuPresentationResources { unsigned char _unknown_0000[0x38]; short voice_id; short voice_started; } UltimateJutsuPresentationResources;

typedef struct CcsExtraPassDescriptor {
    unsigned char _unknown_0000[0xC];
    unsigned int color; // 0x80000000 uses model fallback
    float width_scalar;
    unsigned char _unknown_0014[4]; float alpha;
    unsigned short enabled;
    unsigned char _unknown_001E[2]; float near_width_multiplier; float far_width_multiplier; float near_depth; float far_depth; float minimum_projected_width;
} CcsExtraPassDescriptor;

typedef struct RockLeeCallbackState {
    unsigned char _unknown_0000[0x67F8];
    signed char loop_entry_count;
    signed char presentation_countdown;
    unsigned char _unknown_67FA[0x1E];
    signed char effect_mode;
    unsigned char _unknown_6819[7];
    void *draw_environment;
    unsigned char publish_draw_environment;
    unsigned char _unknown_6825[7];
    void *auxiliary_scene;
    unsigned char _unknown_6830[0x40];
    unsigned char auxiliary_draw_enabled;
    unsigned char _unknown_6871[3];
    CcsExtraPassDescriptor *extra_pass_descriptor;
} RockLeeCallbackState;

typedef struct TentenCallbackState {
    unsigned char _unknown_0000[0x5BB4];
    signed char exit_phase_latch;
    signed char phase_entry_count;
    signed char cleared_work;
} TentenCallbackState;

typedef struct ResponseUpdateCounter {
    short count;
    unsigned char _unknown_0002[2];
    unsigned int update_stamp;
} ResponseUpdateCounter;

typedef struct SubstitutionFallbackSources { unsigned char _unknown_0000[0xE54]; ActionRecord *record; void *source; } SubstitutionFallbackSources;

typedef struct ShadowVuGifTag {
    unsigned short loop_count_and_eop;
    unsigned short control_low;
    unsigned int control_high;
    unsigned long long registers;
} ShadowVuGifTag;

typedef struct ShadowVuParameters {
    float lower_clip_plane[4];
    float upper_clip_plane[4];
    float near_reference[4];
    float fast_lower_bounds[4];
    float fast_upper_bounds[4];
    float model_to_device[16];
    ShadowVuGifTag state_tag;
    ShadowVuGifTag vertex_tag;
    unsigned long long rgbaq_negative[2];
    unsigned long long rgbaq_nonnegative[2];
    unsigned long long alpha_negative[2];
    unsigned long long alpha_nonnegative[2];
    float direction[4];
    float displacement[4];
} ShadowVuParameters;

typedef struct ShadowTopologyPoint {
    short x;
    short y;
    short z;
    short _unknown_w;
} ShadowTopologyPoint;

typedef struct ShadowTopologyTriangle {
    short point_index_a;
    short point_index_b;
    short point_index_c;
    short direction_index;
} ShadowTopologyTriangle;

typedef struct ShadowTopologyEdge {
    short status;
    unsigned char _unknown_0002[2];
    int point_index_a;
    int point_index_b;
    int first_direction_index;
    int second_direction_index;
} ShadowTopologyEdge;

typedef struct ShadowTopologyBuilder {
    unsigned char _unknown_0000[0xA0];
    float *direction_vectors;
    unsigned char _unknown_00A4[0xC];
    int point_a[4];
    int point_b[4];
    int point_c[4];
    int cross_product[4];
    int scratch_cross_product[4];
    int *raw_directions;
    ShadowTopologyTriangle *triangles;
    ShadowTopologyPoint *points;
    ShadowTopologyEdge *edges;
    int point_index_a;
    int point_index_b;
    int point_index_c;
    unsigned char _unknown_011C[8];
    unsigned short construction_status;
    short direction_count;
    int point_count;
    int edge_count;
    int index_count;
    int negative_pair_count;
    int nonnegative_pair_count;
    int removed_shared_edge_count;
} ShadowTopologyBuilder;

typedef struct RendererLimitVector { float x; float y; float z; float plane; } RendererLimitVector;

typedef struct RendererTransformState {
 float inverse_camera_rotation[16];
 float device_projection[16];
 float camera_transform[16];
 float symmetric_projection[16];
 float logical_projection[16];
 float projection_only[16];
 float device_affine[16];
 float transform_2d[16];
 RendererLimitVector device_min;
 RendererLimitVector device_max;
 RendererLimitVector clip_min;
 RendererLimitVector clip_max;
 float camera_reference[4];
 float pixel_left; float pixel_top; float pixel_right; float pixel_bottom;
 unsigned short packed_left; unsigned short packed_right; unsigned short packed_top; unsigned short packed_bottom;
 struct RendererTransformState *next;
 float projection_center_x; float projection_center_y;
 float projection_scale_x; float projection_scale_y;
 float center_offset_x; float center_offset_y;
 float viewport_left; float viewport_top; float viewport_width; float viewport_height;
 float depth_far; float depth_near;
 float field_of_view; float focal_coefficient;
 unsigned char _unknown_02a4[0xc];
} RendererTransformState;

typedef struct DrawTransformRecord2D {
 unsigned char _unknown_0000[0xc];
 float rotation; float scale_x; float scale_y;
 unsigned char _unknown_0018[8];
 float pivot_x; float pivot_y; float offset_x; float offset_y;
 unsigned char _unknown_0030;
 unsigned char packet_branch;
} DrawTransformRecord2D;

typedef struct LazyCameraHolder { RendererTransformState *renderer; CcsAnimationPlayer *player; } LazyCameraHolder;

typedef struct ActionMotionEvent {
    unsigned short flags;
    short event;
    float planar_speed;
    float vertical_speed;
    float decay;
    float multiplier;
} ActionMotionEvent;

typedef struct ActionAttackBank {
    unsigned int flags;
    short start;
    short end;
    float radius;
    char *skeleton_object_name;
    float offset_x;
    float offset_z;
} ActionAttackBank;

typedef struct AuxiliaryAttackTimeline {
    unsigned int animation_result;
    unsigned char _unknown_0004[4];
    TimelineBlock timeline;
    unsigned char _unknown_002c[0x4c];
    CcsAnimationPlayer *scene;
    unsigned char _unknown_007c[4];
} AuxiliaryAttackTimeline;

typedef struct KankuroAttackTimelineView { unsigned char _unknown_0000[0x5520]; AuxiliaryAttackTimeline first_attack_timeline; AuxiliaryAttackTimeline second_attack_timeline; } KankuroAttackTimelineView;

typedef struct ChiyoAttackTimelineView { unsigned char _unknown_0000[0x5bf0]; AuxiliaryAttackTimeline first_attack_timeline; AuxiliaryAttackTimeline second_attack_timeline; } ChiyoAttackTimelineView;

typedef struct SasoriAttackTimelineView {
    unsigned char _unknown_0000[0x4e60];
    unsigned int animation_result;
    unsigned char _unknown_4e64[4];
    TimelineBlock timeline;
    unsigned char _unknown_4e8c[0x68];
    CcsAnimationPlayer *playback_scene;
    unsigned char _unknown_4ef8[0x21c];
    CcsAnimationPlayer *alternate_attack_scene;
} SasoriAttackTimelineView;

typedef struct CharacterAttackScene61d8 { unsigned char _unknown_0000[0x61d8]; CcsAnimationPlayer *scene; } CharacterAttackScene61d8;

typedef struct CharacterAttackScene5084 { unsigned char _unknown_0000[0x5084]; CcsAnimationPlayer *scene; } CharacterAttackScene5084;

typedef struct CharacterAttackScene5494 { unsigned char _unknown_0000[0x5494]; CcsAnimationPlayer *scene; } CharacterAttackScene5494;

typedef struct CharacterAttackSceneSlot { CcsAnimationPlayer *scene; unsigned char _unknown_0004[0x1c]; } CharacterAttackSceneSlot;

typedef struct CharacterAttackScene5880 { unsigned char _unknown_0000[0x5880]; CharacterAttackSceneSlot first_slot; } CharacterAttackScene5880;

typedef struct CharacterRateThresholds { unsigned short thresholds[3]; unsigned char _unknown_0006[2]; short pauses[3]; unsigned char _unknown_000e[2]; short rejections[3]; unsigned char _unknown_0016[2]; } CharacterRateThresholds;

typedef struct HeapNode { struct HeapNode *previous; struct HeapNode *next; unsigned int recorded_bytes; unsigned char flags; unsigned char _unknown_000d[3]; } HeapNode;

typedef struct HeapFreeGap { struct HeapFreeGap *next; struct HeapFreeGap *previous; unsigned int bytes; HeapNode *predecessor; } HeapFreeGap;

typedef struct HeapPlacementScope { int thread_id; unsigned int direction; struct HeapPlacementScope *previous_scope; struct HeapPlacementScope *next_thread; } HeapPlacementScope;

typedef struct RenderPool { struct RenderPool *next; void *first_free; void *backing; void *end; unsigned char flags; unsigned char _unknown_0011[3]; } RenderPool;

typedef struct CcsPointerVector { unsigned int capacity; unsigned int length; void **data; } CcsPointerVector;

typedef long long (*KernelTimerCallback)(unsigned int handle, unsigned long long duration, unsigned long long elapsed, void *context);

typedef struct KernelTimerRecord {
    struct KernelTimerRecord *next;
    struct KernelTimerRecord *previous;
    unsigned int generation;
    unsigned int flags;
    unsigned long long start_count;
    unsigned long long adjustment;
    unsigned long long duration;
    KernelTimerCallback callback;
    void *callback_gp;
    void *context;
    unsigned char _unknown_34[0x0C];
} KernelTimerRecord;

typedef struct KernelAlarmRecord {
    struct KernelAlarmRecord *next_free;
    unsigned int timer_handle;
    KernelTimerCallback callback;
    void *context;
} KernelAlarmRecord;

typedef struct KernelDispatchCommand {
    unsigned char command;
    unsigned char operand;
} KernelDispatchCommand;

typedef struct KernelDispatchQueue {
    unsigned int read_index;
    unsigned int write_index;
    KernelDispatchCommand commands[512];
} KernelDispatchQueue;

typedef struct MpegBuffer {
    unsigned char _unknown_00[0x14];
    int pending_bytes;
    unsigned char _unknown_18[0x28];
    int semaphore_id;
    unsigned int transfer_active;
    unsigned char _unknown_48[0x18];
} MpegBuffer;

typedef struct MpegDecoder {
    unsigned char _unknown_00[0x48];
    MpegBuffer buffer;
    unsigned char _unknown_A8[0x10];
} MpegDecoder;

typedef struct KernelThreadDescriptor {
    unsigned char _unknown_00[4];
    void *entry;
    void *stack;
    unsigned int stack_size;
    void *gp_reg;
    int initial_priority;
    unsigned char _unknown_18[8];
    char *name;
} KernelThreadDescriptor;

typedef struct StartupCardCheck { unsigned int flags; int phase; int choice; char *message; } StartupCardCheck;

typedef struct SplashObject { unsigned char _unknown_0000[4]; int state; unsigned char _unknown_0008[0x10]; float opacity; void *texture; } SplashObject;

typedef struct SplashController { short phase; short phase_counter; unsigned int capacity; unsigned int count; SplashObject **children; short selected_index; unsigned char shared_transition; unsigned char _unknown_0013; } SplashController;

typedef struct LoadingPresentationChild { void *renderer; void *background_animation; void *foreground_animation; void *artwork_animation; unsigned int flags; } LoadingPresentationChild;

typedef struct LoadingPresentationController { int phase; int delay_counter; int exit_transition; int entry_selector; int exit_selector; unsigned char requested; unsigned char owns_artwork; unsigned char _unknown_0016[2]; LoadingPresentationChild *child; } LoadingPresentationController;

typedef struct SndDataStartupDescriptor { void *iop_buffer; unsigned int source; unsigned int allocation_size; unsigned int completion_value; unsigned char _unknown_0010[4]; unsigned int packet_offset; char filename[1]; } SndDataStartupDescriptor;

typedef struct LibraryExitContext { unsigned char _unknown_0000[0x3C]; void *exit_callback; unsigned char _unknown_0040[0x108]; void *callback_lists; } LibraryExitContext;

typedef struct StartupRenderState { unsigned char _unknown_0000[0x70]; float lighting_red; float lighting_green; float lighting_blue; unsigned char _unknown_007c[0x4c]; void *scene_traversal; unsigned char _unknown_00cc[0x44]; unsigned int fog_color; unsigned short blend_selector; unsigned char _unknown_0116[2]; unsigned int frame_mask; unsigned char _unknown_011c; unsigned char texturing_enabled; unsigned char interpolation; unsigned char destination_alpha_test; unsigned char _unknown_0120; unsigned char depth_comparison; unsigned char depth_writes; unsigned char antialias; unsigned char clipping_enabled; unsigned char _unknown_0125[3]; void *bound_texture; unsigned char _unknown_012c[4]; unsigned long long tex1_sampling; float direction_offset; unsigned char _unknown_013c[4]; } StartupRenderState;

typedef struct StartupDrawContext { unsigned char _unknown_0000[0x130]; float texture_u; float texture_v; unsigned char _unknown_0138[0x38]; unsigned int flags; } StartupDrawContext;

typedef struct CardDirectoryCheckTask { unsigned char _unknown_0000[0x28]; int completed; int result; } CardDirectoryCheckTask;

typedef struct BgRotatingSky { BgObject base; void *model; unsigned char _unknown_002c[0x1c]; float angle; unsigned char _unknown_004c[4]; float angular_speed; unsigned char visible; } BgRotatingSky;

typedef struct BgGlareEffect { unsigned char _unknown_0000[0x81]; unsigned char mode; unsigned char _unknown_0082[2]; unsigned int primary_colour; float amount; unsigned int secondary_colour; float parameter_9; } BgGlareEffect;

typedef struct BgGlare { BgObject base; unsigned char _unknown_0028[4]; BgGlareEffect *effect; } BgGlare;

typedef struct RendererOwner { unsigned char _unknown_0000[0x140]; BattleHudRenderContext secondary_environment; BattleHudRenderContext primary_environment; RendererTransformState embedded_renderer; } RendererOwner;

typedef struct SharedSkillInputEvent { unsigned char enabled; unsigned char _unknown_01; short controller_side; unsigned char _unknown_04[0x10]; } SharedSkillInputEvent;

typedef struct StartupOuterState { int state; int substate; } StartupOuterState;

typedef struct MenuLoadTransient { int phase; unsigned char _unknown_0004[0x10]; } MenuLoadTransient;

typedef struct CharacterAttackScene57a0 { unsigned char _unknown_0000[0x57a0]; CcsAnimationPlayer *scene_array; unsigned char _unknown_57a4[0x1c]; float retained_attack_offset[4]; } CharacterAttackScene57a0;

typedef struct RendererPresentationView { unsigned char _unknown_0000[0xE4]; unsigned char factor_byte; unsigned char _unknown_00E5[3]; float amount; unsigned int style; } RendererPresentationView;

typedef struct CcsGeneratorFileHeader {
    unsigned int record_index;
    unsigned int linked_record_index;
    unsigned char packed_controls;
    unsigned char packed_child_count;
    unsigned char packed_parameter_count;
    unsigned char flags;
    unsigned char _unknown_000C[0x48];
} CcsGeneratorFileHeader;

typedef struct CcsEffectFileHeader {
    unsigned int record_index;
    unsigned int texture_record_index;
    unsigned char _unknown_0008[6];
    unsigned short frame_count;
    unsigned char _unknown_0010[0x14];
} CcsEffectFileHeader;

typedef struct CharacterSelectData {
 int fighter_column_count;
 int fighter_ids[2][50];
 unsigned char fighter_states[2][50];
 int support_count;
 unsigned char support_ids[40];
 unsigned char support_states[40];
 void *fighter_portraits[96];
 void *support_portraits[34];
} CharacterSelectData;

typedef struct CharacterSelectRoot {
 int state;
 int mode;
 int assignment_mode;
 int controller[2];
 int dialog_row;
 int transition;
 int result;
 int completion_delay;
 CharacterSelectData data;
 CharacterSelectorInput *selectors[2];
 unsigned char _unknown_0480[0x14];
 void *charsel_sprites;
 void *common_prompts;
 unsigned char _unknown_049c[0x14];
 float footer_pulse_phase;
} CharacterSelectRoot;

typedef struct CharacterPortraitRow {
 int bank;
 unsigned short x;
 unsigned short y;
 unsigned short width;
 unsigned short height;
} CharacterPortraitRow;

typedef struct CharacterSelectDispatchRecord {
 int object_adjustment;
 int dispatch_offset;
 void *entry;
} CharacterSelectDispatchRecord;

typedef struct SupportExclusionRow { unsigned char support; unsigned char fighter; } SupportExclusionRow;

typedef struct SupportIdentityRow { unsigned char support; unsigned char character; unsigned char display; } SupportIdentityRow;

typedef struct SupportLinkedJutsuRow { unsigned char support; unsigned char fighter; short ordinary_jutsu; short replacement_jutsu; } SupportLinkedJutsuRow;

typedef struct CharacterSelectSourceDispatchRecord { CharacterSelectDispatchRecord descriptor; unsigned char padding[4]; } CharacterSelectSourceDispatchRecord;

typedef struct AnimationTrackPair { CcsRecord *record; void *key_descriptor; } AnimationTrackPair;

typedef struct AnimationBlendHeader { unsigned int duration; unsigned short count; unsigned char _unknown_0006[2]; void **items; } AnimationBlendHeader;

typedef struct AnimationEvaluatorHeader { void *descriptor; unsigned char _unknown_0004[0xC]; } AnimationEvaluatorHeader;

typedef struct AnimationTransformTrack { unsigned short tag; unsigned char _unknown_0002[2]; unsigned int channel_modes; void *translation; void *rotation; void *scale; void *alpha; } AnimationTransformTrack;

typedef struct AnimationScalarSegment { unsigned int duration; float delta; } AnimationScalarSegment;

typedef struct AnimationVectorSegment { unsigned int duration; float delta[3]; } AnimationVectorSegment;

typedef struct AnimationScalarWork { float base; unsigned int elapsed; AnimationScalarSegment *segment; unsigned char _unknown_000C[4]; } AnimationScalarWork;

typedef struct AnimationColorSegment { unsigned int duration; unsigned int endpoint; } AnimationColorSegment;

typedef struct AnimationColorWork { unsigned int endpoint; unsigned int elapsed; AnimationColorSegment *segment; unsigned char _unknown_000C[4]; } AnimationColorWork;

typedef struct AnimationVectorWork { float base[3]; unsigned int elapsed; AnimationVectorSegment *segment; unsigned char _unknown_0014[0xC]; } AnimationVectorWork;

typedef struct AnimationCubicVectorWork { float control_points[16]; unsigned int cursor; void *key; unsigned char _unknown_0048[8]; } AnimationCubicVectorWork;

typedef struct AnimationCompactVectorWork { float start[4]; float difference[4]; float current[4]; unsigned int cursor; unsigned short *times; void *packed_values; unsigned char _unknown_003C[4]; } AnimationCompactVectorWork;

typedef struct AnimationRelativeRotationWork { float matrix[16]; unsigned int elapsed; void *segment; unsigned char _unknown_0048[8]; } AnimationRelativeRotationWork;

typedef struct AnimationQuaternionWork { float interpolation_cache[16]; unsigned int cursor; unsigned short *times; void *endpoints; unsigned char _unknown_004C[4]; } AnimationQuaternionWork;

typedef struct AnimationQuaternionBlendCache { float start[4]; float destination_or_difference[4]; float dot; float angle; float sine; unsigned char _unknown_002C[4]; } AnimationQuaternionBlendCache;

typedef struct AnimationTransformSample { unsigned char _unknown_0000[0x80]; float scale[16]; float rotation[16]; float position[4]; unsigned char _unknown_0110[0x34]; float alpha; } AnimationTransformSample;

typedef struct AnimationBlendItem { CcsPlayEntry *entry; void *vtable; unsigned char _unknown_0008[8]; float position[4]; float position_delta[4]; AnimationQuaternionBlendCache quaternion; float scale[4]; float scale_delta[4]; float alpha; float alpha_delta; unsigned char _unknown_0088[8]; } AnimationBlendItem;

typedef struct AnimationNameIndexRow { struct AnimationNameIndexRow *next; unsigned short index; unsigned short hash; void *record; char *suffix; } AnimationNameIndexRow;

typedef struct AnimationNameIndex { AnimationNameIndexRow *head; unsigned short count; unsigned char _unknown_0006[2]; } AnimationNameIndex;

typedef struct AnimationOutputChannel { void *rows; int count; } AnimationOutputChannel;

typedef struct AnimationOutputVectorRow { float values[3]; unsigned char _unknown_000C[0x38]; } AnimationOutputVectorRow;

typedef struct AnimationOutputAlphaRow { float alpha; unsigned char _unknown_0004[0x18]; } AnimationOutputAlphaRow;

typedef struct AnimationAlternateOutput { unsigned char _unknown_0000[0x90]; CcsAnimationPlayer *player; AnimationOutputChannel *position; AnimationOutputChannel *rotation; AnimationOutputChannel *scale; AnimationOutputChannel *alpha; } AnimationAlternateOutput;

typedef struct AnimationModelTransformAttachment { unsigned char _unknown_0000[0xC]; float position_scale; float scale_x; float scale_y; float scale_z; } AnimationModelTransformAttachment;

typedef struct AnimationEffectTransformView { unsigned char _unknown_0000[0xA0]; float scale_x; float scale_y; unsigned char _unknown_00A8[0x4E]; unsigned short restart_marker; } AnimationEffectTransformView;

typedef struct AnimationDeferredScratchView { unsigned char _unknown_0000[0x138]; short first_index; short second_index; } AnimationDeferredScratchView;

typedef struct RenderGsState { unsigned long long reserved; unsigned long long blend; unsigned long long test; unsigned long long primitive; unsigned long long frame; unsigned long long zbuf; unsigned int texture_flags; } RenderGsState;

typedef struct RenderDisplayState { unsigned char _unknown_0000[8]; unsigned short width; unsigned short height; unsigned char _unknown_000c[0x190]; short color_base; unsigned char _unknown_019e[6]; short depth_base; unsigned char _unknown_01a6[6]; unsigned char color_format; unsigned char depth_format; unsigned char _unknown_01ae[2]; unsigned long long zbuf_state; unsigned char _unknown_01b8[8]; void *workspace_cursor; unsigned char _unknown_01c4[0xeb]; unsigned char frame_bank; unsigned char _unknown_02b0[0x60]; unsigned long long primary_frame; unsigned char _unknown_0318[0xe8]; unsigned long long alternate_frame; } RenderDisplayState;

typedef struct CcsRenderMaterial { CcsTextureChunk *texture; void *clut; unsigned char _unknown_0008[4]; CcsMaterialDescriptor *descriptor; float alpha; short u_offset; short v_offset; short u_scale; short v_scale; } CcsRenderMaterial;

typedef struct CcsDescriptorPassOwner { unsigned char _unknown_0000[0x10]; CcsTextureChunk *texture; void *clut; unsigned char _unknown_0018[4]; unsigned short enabled; unsigned char blend_selector; unsigned char test_selector; unsigned int color; unsigned int vu_parameter; float alpha; } CcsDescriptorPassOwner;

typedef struct CcsContext2Descriptor { unsigned char _unknown_0000[0x10]; CcsTextureChunk *texture; void *clut; unsigned char _unknown_0018[4]; unsigned short enabled; unsigned char _unknown_001e[0xe]; unsigned char blend_selector; unsigned char _unknown_002d[3]; float alpha; } CcsContext2Descriptor;

typedef struct CcsEffectDrawDescriptor { float position[4]; float scale_x; float scale_y; float rotation; unsigned int color; unsigned short frame_count; unsigned short primitive; float projection_offset; float alpha; CcsTextureChunk *texture; void *clut; unsigned char _unknown_0034[4]; CcsRecord *record; struct CcsEffectFrame *frames; unsigned int packed_dimensions; unsigned char _unknown_0044[4]; unsigned long long blend_state; unsigned long long test_state; unsigned char draw_state; } CcsEffectDrawDescriptor;

typedef struct FontDrawState { unsigned char _unknown_0000[4]; float cell_width; float cell_height; unsigned int output_width; unsigned int output_height; unsigned char _unknown_0014[8]; float glyph_x; float glyph_y; unsigned char _unknown_0024[0x14]; unsigned int trailing_margin; float tracking; float line_extra; unsigned char _unknown_0044[0xe]; unsigned short blend_selector; unsigned char alternate_orientation; unsigned char _unknown_0055[3]; void *ruby; void *raster; void *palette; unsigned char _unknown_0064[4]; struct FontRasterDescriptor *glyph_descriptor; void *render_context; unsigned char render_flags; unsigned char _unknown_0071[0xb]; void *icon_measure_callback; } FontDrawState;

typedef struct SpSkillAssetPassView { unsigned char _unknown_0000[0xfc]; void *extra_pass_block; void *descriptor_pass_block; } SpSkillAssetPassView;

typedef struct DrawTransformOwnerView { DrawTransformRecord2D record; unsigned char _unknown_0034[0xc]; BattleHudRenderContext *environment; unsigned char _unknown_0044[6]; short draw_enabled; unsigned char _unknown_004c[0xc]; float uniform_scale; float rotation; unsigned int color_or_mode; unsigned char _unknown_0064[0x1c]; unsigned char packet_mode; unsigned char _unknown_0081[3]; float pivot_x; float pivot_y; float offset_x; float offset_y; } DrawTransformOwnerView;

typedef struct FighterPhase2DrawView { unsigned char _unknown_0000[0x2c]; DrawTransformOwnerView *draw_owner; } FighterPhase2DrawView;

typedef struct PresentationEffectDrawView { unsigned char _unknown_0000[0x1c]; int environment_index; unsigned char _unknown_0020[0x20]; DrawTransformRecord2D record; unsigned char _unknown_0074[0xc]; float uniform_scale; float rotation; unsigned int color_or_mode; } PresentationEffectDrawView;

typedef struct SamplingTextureCaptureView { unsigned char _unknown_0000[0x32]; unsigned short width; unsigned short height; } SamplingTextureCaptureView;

typedef struct WoodTimerNode { unsigned char _unknown_0000[4]; struct WoodTimerNode *next; short duration; unsigned char _unknown_000a[6]; TimelineBlock timeline; unsigned char _unknown_0034[0x28]; float minimum_delta; } WoodTimerNode;

typedef struct CharacterTimeline6168 { unsigned char _unknown_0000[0x6168]; TimelineBlock timeline; } CharacterTimeline6168;

typedef struct ContentListNode { void *title; int content_id; unsigned char cached_state; unsigned char _unknown_09[3]; struct ContentListNode *next; } ContentListNode;

typedef struct ContentListOwner { unsigned char _unknown_00[0x58]; ContentListNode *head; ContentListNode *tail; int count; unsigned char _unknown_64[0xC]; } ContentListOwner;

typedef struct CollectionMovieViewer { unsigned char _unknown_00[0x5C]; ContentListOwner *list; } CollectionMovieViewer;

typedef struct BattleItemSelectionView { unsigned char _unknown_00[0x10]; int cursor; unsigned char _unknown_14[8]; signed char selected_units[22]; } BattleItemSelectionView;

typedef struct JutsuCharacterExclusionRow { int character; int list; } JutsuCharacterExclusionRow;

typedef struct DioramaCharacterLink { int character; unsigned char _unknown_04[8]; } DioramaCharacterLink;

typedef struct DioramaContentRecord { int content_id; unsigned char _unknown_04[0x10]; DioramaCharacterLink characters[6]; unsigned char _unknown_5c[0x2C]; } DioramaContentRecord;

typedef struct CollectionBundleRecord { int character; int price; int first_record; int count; void *records; } CollectionBundleRecord;

typedef struct CollectionContentRecord { int content_id; unsigned char _unknown_04[0xC]; } CollectionContentRecord;

typedef struct CcsEffectFrame { unsigned short u; unsigned short v; unsigned short alpha; unsigned char _unknown_0006[2]; } CcsEffectFrame;

typedef struct CcsSamplingTexture { CcsTextureChunk base; unsigned char _unknown_0048[4]; unsigned char _unknown_004c[4]; } CcsSamplingTexture;

typedef struct PaletteReflectionController { CcsClut *palette; unsigned int *colors; int color_count; unsigned int *snapshot; float accumulator; float increment; int shift; int range_begin; int range_end; unsigned char repeat; unsigned char complete; unsigned char _unknown_0026[2]; } PaletteReflectionController;

typedef struct PaletteRgbController { CcsClut *owned_clut; unsigned short color_count; unsigned char _unknown_0006[2]; unsigned int *colors; unsigned int *original; unsigned int *target; unsigned char _unknown_0014[0xc]; float red_multiplier; float green_multiplier; float blue_multiplier; unsigned char _unknown_002c[4]; } PaletteRgbController;

typedef struct PaletteScriptOwnerView { unsigned char _unknown_0000[8]; float update_scalar; unsigned char _unknown_000c[0x2c]; CcsContainer *container; } PaletteScriptOwnerView;

typedef struct PaletteReflectionWrapper { void *vtable; PaletteScriptOwnerView *owner; int list_index; unsigned char _unknown_000c[8]; void *arguments; unsigned char _unknown_0018[0x10]; PaletteReflectionController *controller; float increment; } PaletteReflectionWrapper;

typedef struct SamplingRenderContextView { unsigned char _unknown_0000[8]; unsigned short width; unsigned short height; unsigned char _unknown_000c[0x190]; short framebuffer_base; unsigned char _unknown_019e[0xe]; unsigned char framebuffer_format; } SamplingRenderContextView;

typedef struct SpriteTextureBindingView { unsigned char _unknown_0000[0xd8]; unsigned long long tex0_state; unsigned long long tex1_state; unsigned char _unknown_00e8[4]; CcsTextureChunk *texture; CcsClut *clut; } SpriteTextureBindingView;

typedef struct CcsTextureInitDescriptor { unsigned short flags; unsigned char pixel_format; unsigned char width_log2; unsigned char height_log2; unsigned char extra_levels; unsigned char alpha_reference; unsigned char _unknown_0007; short level_coordinates[8]; void *pixels; } CcsTextureInitDescriptor;

typedef struct CcsModelFileHeader { unsigned char _unknown_0000[0x14]; unsigned short draw_modes; } CcsModelFileHeader;

typedef struct GsRegisterPair { unsigned long long value; unsigned long long register_id; } GsRegisterPair;

typedef struct ModelMaterialStatePacket { unsigned char _commands[0x20]; GsRegisterPair texture_flush; GsRegisterPair clamp; GsRegisterPair texture; GsRegisterPair mipmap; GsRegisterPair sampling; GsRegisterPair blend; GsRegisterPair test; GsRegisterPair depth; GsRegisterPair fog; GsRegisterPair fog_color; GsRegisterPair primitive; unsigned char _vu_parameters[0x30]; } ModelMaterialStatePacket;

typedef struct CcsEffectScene { float world_matrix[16]; float local_matrix[16]; void *parent; float inherited_factor; float alpha; unsigned char alpha_flags; unsigned char matrix_dirty; unsigned short type_tag; CcsEffectDrawDescriptor draw; unsigned char _unknown_00f0[6]; unsigned short frame; } CcsEffectScene;

typedef struct JutsuSelectRow { unsigned char _unknown_00[4]; int character; short selectors[2]; } JutsuSelectRow;

typedef struct JutsuSelectMenuView { unsigned char _unknown_00[0x34]; int character; } JutsuSelectMenuView;

typedef struct ProjectedTextGeometryView { int disabled; unsigned int geometry_flags; unsigned char _unknown_0008[0x18]; int rectangle_count; int rectangle_capacity; unsigned char _unknown_0028[4]; void *packet; unsigned char _unknown_0030[0x10]; float opacity; float local_x; float local_y; float rotation; float x; float y; float width; float height; int source_width; int source_height; int source_u_fixed4; int source_v_fixed4; int source_mode; } ProjectedTextGeometryView;

typedef struct UiTransitionSlot { unsigned short flags; short cursor; short duration; short second_duration; short intermediate_duration; unsigned char _unknown_000a[2]; float x; float y; float width; float height; unsigned int start_color; unsigned int end_color; } UiTransitionSlot;

typedef struct UiTransitionPool { int gate; UiTransitionSlot slots[4]; void *render_context; } UiTransitionPool;

typedef struct UiPanel { int style; float x; float y; float width; float height; int resting_style; float resting_x; float resting_y; float resting_width; float resting_height; unsigned char _unknown_0028[8]; short border_x; short border_y; unsigned char _unknown_0034[0xc]; short state; unsigned char _unknown_0042[4]; short cursor; short duration; unsigned char _unknown_004a[0xe]; float fraction; unsigned char _unknown_005c[6]; unsigned char text_enabled; unsigned char hide_transition_text; unsigned char opening_sound_enabled; unsigned char _unknown_0065[7]; void *render_context; unsigned char _unknown_0070[4]; union { void *content_render_context; void *text_context; }; void *text_draw_object; unsigned char _unknown_007c[4]; } UiPanel;

typedef struct UiPanelRectangleRecord { short style; short x; short y; short width; short height; } UiPanelRectangleRecord;

typedef struct UiPulseSample { float x; float y; float scale_x; float scale_y; } UiPulseSample;

typedef struct UiScrollSegment { unsigned char owns_string; unsigned char _unknown_0001[3]; char *string; float extent; struct UiScrollSegment *next; } UiScrollSegment;

typedef struct UiScrollingStrip { float viewport_width; float viewport_height; void *text_context; void *backing_context; void *backing_sprite; int textured_backing; float text_axis_offset; unsigned int text_color; unsigned int backing_color; unsigned char vertical; unsigned char _unknown_0025[3]; unsigned int text_opacity; UiScrollSegment *head; float distance; float speed; short delay; short elapsed_delay; unsigned char enqueue_inhibited; unsigned char minimum_first_extent; unsigned char _unknown_003e[2]; } UiScrollingStrip;

typedef struct UiScrollConfiguration { float x; float y; float width; float height; float text_axis_offset; unsigned int text_color; unsigned int backing_color; unsigned char vertical; unsigned char _unknown_001d[3]; float speed; } UiScrollConfiguration;

typedef struct OptionsAudioPresentation { CcsAnimationPlayer *decoration; unsigned char _unknown_0004[0x1c]; UiScrollingStrip *strip; short selected_row; unsigned char _unknown_0026[2]; int selected_choice; unsigned char _unknown_002c[0xc]; short pulse_counter; unsigned char _unknown_003a[2]; float arrow_phase; unsigned char _unknown_0040[0x20]; CcsAnimationPlayer *row_change_player; unsigned char _unknown_0064[0x10]; float choice_weights[2]; float row_weights[2]; } OptionsAudioPresentation;

typedef struct SupportElevationView { SupportObject base; float elevation; } SupportElevationView;

typedef struct SupportMovingPointView { SupportObject base; float local_position[4]; } SupportMovingPointView;

typedef struct SkillPairPlacementView { unsigned char _unknown_0000[0x31C]; Fighter *first_participant; unsigned char _unknown_0320[0x1AC]; Fighter *second_participant; } SkillPairPlacementView;

typedef struct StoredCursorPlayback { CcsAnimationPlayer *player; int complete; unsigned int frame; } StoredCursorPlayback;

typedef struct LifetimeAnimationOwner { unsigned char _unknown_0000[0x68]; unsigned int updates; int lifetime; unsigned char _unknown_0070[0x40]; CcsAnimationPlayer *player; unsigned int complete; } LifetimeAnimationOwner;

typedef struct BgAnimationPlaybackView { BgObject base; CcsAnimationPlayer *player; float original_step; float rate_multiplier; } BgAnimationPlaybackView;

typedef struct BgDistanceAnimationPlaybackView { BgAnimationPlaybackView base; float initial_opacity; int disabled; int fade_enabled; float fade; } BgDistanceAnimationPlaybackView;

typedef struct BgShadowPlaybackView { BgObject base; void *projection; CcsAnimationPlayer *player; float original_step; float rate_multiplier; union { float opacity; float projection_scalar; }; /* +0x38 draw writes projection_scalar; prior opacity view retained */ } BgShadowPlaybackView;

typedef struct MovingAnimationPlaybackView { unsigned char _unknown_0000[0x34]; CcsAnimationPlayer *player; CcsAnimationDescriptor *animations[3]; } MovingAnimationPlaybackView;

typedef struct FighterAuxiliaryPlayback { CcsAnimationPlayer *player; CcsAnimationDescriptor *animation; unsigned char _unknown_0008[0xC]; unsigned int complete; } FighterAuxiliaryPlayback;

typedef struct PairedPresentationPlayerSet { CcsAnimationPlayer *first_players[3]; unsigned char _unknown_000C[0x64]; CcsAnimationPlayer *second_players[3]; } PairedPresentationPlayerSet;

typedef struct PairedPresentationOwner { unsigned char _unknown_0000[8]; CcsAnimationPlayer *outer_player; unsigned char _unknown_000C[0x20]; PairedPresentationPlayerSet *players; } PairedPresentationOwner;

typedef struct EtcFiveSlotPlayback { int state; int list_count; int slot_list[1]; unsigned char _unknown_000C[0x14]; int selection; unsigned char _unknown_0024[4]; float fade; unsigned char _unknown_002C[0x14]; CcsAnimationPlayer *players[5]; } EtcFiveSlotPlayback;

typedef struct SpSkillAppearanceRow { char *source_container_name; char *source_palette_name; char *target_name; } SpSkillAppearanceRow;

typedef struct SpSkillOpponentOverride { short replacement_skill; short requested_skill; char *path; } SpSkillOpponentOverride;

typedef struct SpSkillOpponentGroup { short defender_id; short entry_count; SpSkillOpponentOverride *entries; } SpSkillOpponentGroup;

typedef struct SpSkillFrameRange { unsigned short first_frame; unsigned short last_frame; } SpSkillFrameRange;

typedef struct SpSkillDrawGate { int range_count; SpSkillFrameRange *ranges; int defender_count; short *defender_ids; } SpSkillDrawGate;

typedef struct SpSkillPositionRule { short defender_id; short first_frame; short last_frame; unsigned char _unknown_0006[0xA]; float position[4]; } SpSkillPositionRule;

typedef struct SpSkillPositionGroup { short skill; unsigned char _unknown_0002[2]; SpSkillPositionRule *entries; short entry_count; unsigned char _unknown_000A[2]; } SpSkillPositionGroup;

typedef struct SpSkillObjectRule { short defender_id; short first_frame; short last_frame; unsigned char _unknown_0006[2]; char *command; } SpSkillObjectRule;

typedef struct SpSkillObjectGroup { short skill; unsigned char _unknown_0002[2]; SpSkillObjectRule *entries; short entry_count; unsigned char _unknown_000A[2]; } SpSkillObjectGroup;

typedef struct SpSkillTextureEntry { short skill; unsigned char _unknown_0002[2]; unsigned int frame; char *source_container_name; char *original_texture_name; char *replacement_texture_name; char *target_name; } SpSkillTextureEntry;

typedef struct SpSkillPaletteTarget { unsigned char _unknown_0000[4]; void *palette; } SpSkillPaletteTarget;

typedef struct SpSkillBoneReplacement { CcsScenePlayTarget *target; CcsModelInstance *replacement; void *original; } SpSkillBoneReplacement;

typedef struct SpSkillHitPopup { unsigned char _unknown_0000[0x14]; short active; unsigned char _unknown_0016[0xE]; } SpSkillHitPopup;

typedef struct CollectionRosterRecord { char *display_name; unsigned char metadata[8]; } CollectionRosterRecord;

typedef struct CollectionUltimateRecord { char *display_name; unsigned int metadata[3]; } CollectionUltimateRecord;

typedef struct CollectionUltimateScreenRecord { unsigned int metadata[3]; char *display_name; } CollectionUltimateScreenRecord;

typedef struct CollectionVoiceRecord { char *display_name; unsigned int voice_id; unsigned int type; } CollectionVoiceRecord;

typedef struct EffectPoolController { WrappedScenePlayback *records; WrappedScenePlayback *head; int capacity; int search_half; unsigned int generation_counter; void *vtable; } EffectPoolController;

typedef struct RegisteredEffectRecord { void *object; unsigned int serial; unsigned char kind; unsigned char _unknown_0009[3]; } RegisteredEffectRecord;

typedef struct EffectManagerView {
    unsigned char _unknown_0000[0x3f4];
    EffectPoolController * controllers[8]; // +0x3F4
    int controller_count; // +0x414
    void * controller_list_vtable; // +0x418
    EffectPoolController draw_pool; // +0x41C
    EffectPoolController hit_mark_pool; // +0x434
    unsigned char _unknown_044c[0x38];
    EffectPoolController illustration_pool; // +0x484
    unsigned char _unknown_049c[0xa8];
    RegisteredEffectRecord records[0x300]; // +0x544
    unsigned char _unknown_2944[0x878];
    void * vtable; // +0x31BC
} EffectManagerView;

typedef struct RegisteredEffectObjectView {
    void * vtable; // +0x0
    SupportIndexedHandle handle; // +0x4
    unsigned int serial; // +0x10
    int manager_index; // +0x14
    EffectManagerView * manager; // +0x18
    int view_index; // +0x1C
    unsigned char _unknown_0020[0x4];
    unsigned char removal_flags; // +0x24
    unsigned char _unknown_0025[0x3];
    int signed_delay; // +0x28
    unsigned char _unknown_002c[0xc];
    unsigned char update_enabled; // +0x38
    unsigned char draw_enabled; // +0x39
} RegisteredEffectObjectView;

typedef struct SkillBlowWatchView {
    unsigned char _unknown_0000[0xa42];
    unsigned char first_ready; // +0xA42
    unsigned char second_ready; // +0xA43
    unsigned char _unknown_0a44[0xfc];
    Fighter * retained_actor; // +0xB40
    unsigned char _unknown_0b44[0x4c];
    int mode; // +0xB90
} SkillBlowWatchView;

typedef struct SkillComboServiceView {
    unsigned char _unknown_0000[0x10b8];
    unsigned char pending_callback; // +0x10B8
} SkillComboServiceView;

typedef struct WrappedScenePlaybackVtableView { unsigned char _unknown_0000[0x18]; void *retire; } WrappedScenePlaybackVtableView;

typedef struct VisibilityBounds {
    float minimum[4]; // +0x0
    float maximum[4]; // +0x10
    float midpoint[4]; // +0x20
} VisibilityBounds;

typedef struct BgVisibilityRayView {
    unsigned char _unknown_0000[0x60];
    float bounds_minimum[4]; float bounds_maximum[4]; // +0x60
    unsigned char _unknown_0080[0xb0];
    float position[4]; // +0x130
    unsigned char _unknown_0140[0x4];
    unsigned char visible; // +0x144
} BgVisibilityRayView;

typedef struct BgVisibilityPlacementView {
    unsigned char _unknown_0000[0x10];
    float bounds_minimum[4]; float bounds_maximum[4]; // +0x10
    unsigned char _unknown_0030[0xb0];
    float position[4]; // +0xE0
    unsigned char _unknown_00f0[0x8];
    unsigned char visible; // +0xF8
} BgVisibilityPlacementView;

typedef struct BgInlineVisibilityView {
    unsigned char _unknown_0000[0x10];
    float transform[16]; // +0x10
    void *bounds; // +0x50
} BgInlineVisibilityView;

typedef struct BgVisibilityModelOwnerView {
    unsigned char _unknown_0000[0x28];
    CcsScenePlayTarget * model; // +0x28
} BgVisibilityModelOwnerView;

typedef struct BgVisibilityChildView {
    CcsScenePlayTarget scene; // +0x0
    unsigned char _unknown_00ac[0x28];
    unsigned int visible; // +0xD4
    unsigned char _unknown_00d8[8]; // established array stride 0xE0
} BgVisibilityChildView;

typedef struct BgVisibilityGrassView {
    unsigned char _unknown_0000[0x4];
    BgScene * scene; // +0x4
    unsigned char _unknown_0008[0x20];
    unsigned char child_count; // +0x28
    unsigned char _unknown_0029[0x3];
    BgVisibilityChildView * children; // +0x2C
} BgVisibilityGrassView;

typedef struct BgVisibilitySwayView {
    unsigned char _unknown_0000[0x28];
    CcsScenePlayTarget * model; // +0x28
    unsigned char _unknown_002c[0x74];
    float phase; // +0xA0
    float speed; // +0xA4
    unsigned char _unknown_00a8[0x8];
    unsigned char visible; // +0xB0
} BgVisibilitySwayView;

typedef struct BgVisibilityUvView {
    unsigned char _unknown_0000[0x28];
    CcsScenePlayTarget * model; // +0x28
    float u; // +0x2C
    float v; // +0x30
    float u_speed; // +0x34
    float v_speed; // +0x38
    unsigned int visible; // +0x3C
} BgVisibilityUvView;

typedef struct BgVisibilityClothView {
    unsigned char _unknown_0000[0x28];
    unsigned int visible; // +0x28
    CcsScenePlayTarget * first_child; // +0x2C
    CcsScenePlayTarget * second_child; // +0x30
    unsigned char _unknown_0034[0xfc];
    unsigned char countdown; // +0x130
} BgVisibilityClothView;

typedef struct BgVisibilitySharedPlacementsView {
    unsigned char _unknown_0000[0x28];
    CcsScenePlayTarget * model; // +0x28
    int placement_count; // +0x2C
    void * placements; // +0x30
} BgVisibilitySharedPlacementsView;

typedef struct BgVisibilityMatrixPlacementsView {
    unsigned char _unknown_0000[0x28];
    unsigned char child_count; // +0x28
    unsigned char _unknown_0029[0x3];
    BgVisibilityChildView * children; // +0x2C
    unsigned char _unknown_0030[0x30];
    int placement_count; // +0x60
    float * matrices; // +0x64
} BgVisibilityMatrixPlacementsView;

typedef struct BgVisibilityVertexView {
    unsigned char _unknown_0000[0x28];
    CcsScenePlayTarget * model; // +0x28
    unsigned char _unknown_002c[0x18];
    float distance_max; // +0x44
    int vertex_count; // +0x48
    void * oscillations; // +0x4C
    unsigned int visible; // +0x50
} BgVisibilityVertexView;

typedef struct BgVisibilityAuxRotationView {
    unsigned char _unknown_0000[0x28];
    CcsScenePlayTarget * model; // +0x28
    unsigned char _unknown_002c[0x64];
    float angle; // +0x90
    float angular_speed; // +0x94
    unsigned char _unknown_0098[0x4];
    unsigned int visible; // +0x9C
} BgVisibilityAuxRotationView;

typedef struct BgVisibilityTriggerView {
    unsigned char _unknown_0000[0x28];
    unsigned int visible; // +0x28
    CcsScenePlayTarget * model; // +0x2C
    unsigned char _unknown_0030[0x2c];
    float u_scale; // +0x5C
    float v_scale; // +0x60
    float draw_factor; // +0x64
    unsigned char _unknown_0068[0x4];
    int countdown; // +0x6C
} BgVisibilityTriggerView;

typedef struct BgVisibilityRangeView {
    unsigned char _unknown_0000[0x2c];
    CcsScenePlayTarget * model; // +0x2C
    int range_min; // +0x30
    int range_max; // +0x34
} BgVisibilityRangeView;

typedef struct ProjectionVisibilityControllerView {
    unsigned char _unknown_0000[0x4c];
    RendererTransformState * renderer; // +0x4C
    unsigned char _unknown_0050[0x10c];
    unsigned char mode; // +0x15C
} ProjectionVisibilityControllerView;

typedef struct UiColoredRectangleRecord { unsigned int color; float x; float y; float width; float height; } UiColoredRectangleRecord;

typedef struct MovieBarBounds { int right_x; int bottom_y; int upper_end_y; int lower_start_y; } MovieBarBounds;

typedef struct BtlWindowDimmerView { unsigned char _unknown_00[4]; UiPanel *parent; unsigned char _unknown_08[0x1c]; float modal_opacity; } BtlWindowDimmerView;

typedef struct BtlTwoBoxDrawView { unsigned char _unknown_00[4]; UiPanel *parent; unsigned char _unknown_08[0x10]; UiPanel *modal_panel; unsigned char _unknown_1c[8]; float modal_opacity; } BtlTwoBoxDrawView;

typedef struct SceneVisibilitySubmissionView { unsigned char _unknown_0000[0xF7]; unsigned char composition_draw_flags; void *attached_manager; } SceneVisibilitySubmissionView;

typedef struct ShadowDmaReference { unsigned short quadwords; unsigned char _unknown_0002; unsigned char tag_kind; void *source; unsigned char _unknown_0008[8]; } ShadowDmaReference;

typedef struct ShadowProjectionPacket { ShadowDmaReference microprogram_reference; unsigned char parameter_commands[0x20]; ShadowVuParameters parameters; unsigned int geometry_start_commands[4]; ShadowDmaReference geometry_reference; unsigned char terminal_tag[0x10]; } ShadowProjectionPacket;

typedef struct RenderDmaTag { unsigned short qwc; unsigned char _unknown_02; unsigned char id_flags; void *address; unsigned int command0; unsigned int command1; } RenderDmaTag;

typedef struct RenderPacketHead { RenderPoolAllocation *blocks; RenderDmaTag *first_packet; RenderDmaTag *last_packet; } RenderPacketHead;

typedef struct RenderPacketList { RenderPacketHead *construction; RenderPacketHead *submission; RenderPacketHead heads[2]; } RenderPacketList;

typedef struct RenderOrderingNode { float key; struct RenderOrderingNode *left; struct RenderOrderingNode *right; RenderDmaTag *first_packet; RenderDmaTag *last_packet; } RenderOrderingNode;

typedef struct RenderOrderingTree { RenderOrderingNode *root; int max_depth; } RenderOrderingTree;

typedef struct CurvePacketState { unsigned int half_index; float depth_sum; int strip_count; unsigned int half_quadwords; RenderDmaTag *packet; } CurvePacketState;

typedef struct RenderDmaContinuation { RenderDmaTag tag; unsigned short resume_qwc; unsigned char _unknown_12; unsigned char resume_id_flags; void *resume_address; void *callback; void *callback_argument; } RenderDmaContinuation;

typedef struct GsDisplayEnvironment { unsigned long long pmode; unsigned long long mode; unsigned long long framebuffer; unsigned long long display; unsigned long long background_or_extdata; } GsDisplayEnvironment;

typedef struct GsDrawEnvironmentFieldView { unsigned char _unknown_0000[0x20]; unsigned long long xyoffset; unsigned char _unknown_0028[8]; unsigned long long scissor; } GsDrawEnvironmentFieldView;

typedef struct RenderInterruptHandlerRecord { short enabled; unsigned short channel; void *handler; } RenderInterruptHandlerRecord;

typedef struct ComboScalingFighterView {
    unsigned char _unknown_0000[0x20];
    Fighter *opponent; // +0x20 paired attacker for damage
    unsigned char _unknown_0024[0x3C];
    unsigned char control_flags; // +0x60 low bit selects combo side
    unsigned char _unknown_0061[0x9E4];
    signed char pending_combo_hits; // +0xA45 pending accepted-hit count
    unsigned char _unknown_0A46[0x16A];
    unsigned int side_damage_attributes; // +0xBB0 bit 0x400 selects 0.04 contact damage for 0x42/0x43
    unsigned int movement_flags; // +0xBB4 bit 0x400 selects 0.04 contact damage for 0x45..0x47
    unsigned char _unknown_0BB8[4];
    unsigned int ceiling_damage_attributes; // +0xBBC bit 0x400 selects 0.04 contact damage for 0x44
} ComboScalingFighterView;

typedef struct SurvivalRankingView { unsigned char _unknown_0000[0x10]; int ranking_row; int transition_countdown; int repeat_countdown; } SurvivalRankingView;

typedef struct SurvivalResultWrapper { int kind; int state; struct SurvivalWinResult *win_result; BtlSaveResultController *course_result; } SurvivalResultWrapper;

typedef struct SurvivalWinResult { unsigned char _unknown_0000[0xC]; int ranking_result; unsigned char _unknown_0010[0x2C]; int character_id; int wins; SurvivalRankingView *ranking_child; unsigned char _unknown_0048[4]; int ranking_row; unsigned char _unknown_0050[4]; short opponent_count; unsigned char _unknown_0056[2]; void *opponents; } SurvivalWinResult;

typedef struct SurvivalCourseDescriptor { void *type_info; unsigned char _unknown_0004[4]; void *draw_reward; void *counter_index; void *compute_reward; void *enter_state; } SurvivalCourseDescriptor;

typedef struct SurvivalSelectionNode { unsigned char _unknown_0000[0xC]; int kind; unsigned char _unknown_0010[0x2C]; SurvivalRankingView *course_selection; } SurvivalSelectionNode;

typedef struct SurvivalSetupOwner { unsigned char _unknown_0000[0x1C]; SurvivalSelectionNode *selected_node; EncounterFlow *flow; } SurvivalSetupOwner;

typedef struct SurvivalCourseSelector { unsigned char _unknown_0000[0xC]; int selected_group; int selected_course; } SurvivalCourseSelector;

// Partial owner view used by the two verified native midpoint-placement consumers; enclosing gameplay role remains unclassified.
typedef struct PairPlacementOwner {
    unsigned char _unknown_0000[0x31C];
    Fighter *first_fighter; // +0x31C; selected object, gated by first_enabled and eligibility
    unsigned char _unknown_0320[0x10];
    float first_position[4]; // +0x330
    float first_orientation[4]; // +0x340
    unsigned char _unknown_0350[0x39];
    unsigned char first_enabled; // +0x389
    unsigned char _unknown_038A[0x142];
    Fighter *second_fighter; // +0x4CC; selected object, gated by second_enabled and eligibility
    unsigned char _unknown_04D0[0x10];
    float second_position[4]; // +0x4E0
    float second_orientation[4]; // +0x4F0
    unsigned char _unknown_0500[0x39];
    unsigned char second_enabled; // +0x539
} PairPlacementOwner;

typedef struct OptionsControlsRows { int action_indices[8]; int vibration; } OptionsControlsRows;

typedef struct OptionsControlsView { int state; int interaction_modes[2]; int selected_rows[2]; OptionsControlsRows rows[2]; int staged_values[2]; unsigned char vibration_cooldowns[2]; unsigned char _unknown_66[2]; void *menu_sprite; void *face_sprite; void *shoulder_sprite; void *prompt_sprite; void *render_context; void *prompt_context; void *background_player; void *camera_player; void *row_frames[2]; void *help; short pulse_counter; unsigned char _unknown_96[2]; float cursor_phase; int exit_delay; } OptionsControlsView;

typedef struct ScreenPositionView { void *sprite; void *prompt_sprite; void *legend_sprite; unsigned char _unknown_0c[4]; void *render_context; void *panel; unsigned int color; short x_offset; short y_offset; short staged_x; short staged_y; } ScreenPositionView;

typedef struct OptionsRootView { unsigned char owns_archive; unsigned char _unknown_01[3]; void *archive; void *render_context; void *prompt_context; void *decoration_player; void *camera_player; void *background_player; void *label_sprite; void *selection_sprite; void *prompt_sprite; void *help; unsigned char _unknown_2c[8]; int transition_slot; short phase; short selected_row; unsigned char _unknown_3c[8]; OptionsControlsView *controls; void *audio; ScreenPositionView *display; void *save_dialog; unsigned int pressed; unsigned int repeated; } OptionsRootView;

typedef struct OptionsSpriteColorView { unsigned char _unknown_00[0x90]; unsigned long long red_green; unsigned long long blue; } OptionsSpriteColorView;

typedef struct CharacterResourceLookupHolder { void **resources; unsigned int count; } CharacterResourceLookupHolder;

typedef struct CharacterResourceTemplate { union { int family; char *path; } provider; char *name_template; } CharacterResourceTemplate;

typedef struct EndDemoModelWorkView { CcsRecord *record; void *work; unsigned char _unknown_0008[0x10]; unsigned int flags; } EndDemoModelWorkView;

typedef struct EndDemoAnimationInstance { CcsAnimationPlayer *player; unsigned char complete; unsigned char _unknown_0005[3]; EndDemoModelWorkView *work_targets[2]; unsigned char _unknown_0010[4]; } EndDemoAnimationInstance;

typedef struct EndDemoController { int state; unsigned int flags; unsigned char _unknown_0008[4]; AwakeningPauseGate *configuration; unsigned char _unknown_0010[0x140]; CharacterResourceLookupHolder lookups[2]; CcsContainer *enddemo_container; CcsAnimationPlayer *regular_players[8]; unsigned char _unknown_0184[0x14]; EndDemoAnimationInstance repeated_instances[3]; unsigned char _unknown_01d4[0x248]; EndDemoAnimationInstance selected_instance; } EndDemoController;

typedef struct EndDemoDrawNodeView { unsigned char _unknown_0000[0x40]; float local_translation[4]; } EndDemoDrawNodeView;

typedef struct ExchangeAttackMotionView { short animation_slot; unsigned char _unknown_0002[6]; unsigned short motion_flags; short event_gate; float planar_speed; float vertical_speed; float damping; float gravity_aux; } ExchangeAttackMotionView;

typedef struct ExchangeModeView { unsigned char _unknown_0000[0x14]; int mode; } ExchangeModeView;

typedef struct ExchangeContextView { unsigned char _unknown_0000[8]; ExchangeModeView *mode_owner; } ExchangeContextView;

typedef struct FrontendFontSpacingView { unsigned char _unknown_00[0x3c]; float tracking; float extra_spacing; } FrontendFontSpacingView;

typedef struct CcsViewerControl { unsigned char _unknown_0000[0x90]; float rotation_progress; float movement_progress; short hold_count; unsigned char _unknown_009A[2]; float pitch_degrees; float yaw_degrees; float roll_degrees; unsigned char mode_flags; } CcsViewerControl;

typedef struct SasukeEffectCountdown { short count; unsigned char _unknown_0002[2]; unsigned int update_stamp; void *effect; } SasukeEffectCountdown;

typedef struct SasukeTimingFighterView { unsigned char _unknown_0000[0x1AC]; float update_rate; unsigned char _unknown_01B0[0x6018]; SasukeEffectCountdown effect_countdowns[2]; } SasukeTimingFighterView;

typedef struct CcsAlphaTargetLink { struct CcsAlphaTargetLink *next; CcsScenePlayTarget *target; } CcsAlphaTargetLink;

typedef struct CcsAlphaGroup { struct CcsAlphaGroup *next; void *environment; CcsAlphaTargetLink *targets; } CcsAlphaGroup;

typedef struct CollectionSpritePosition { float x; float y; float z; float w; } CollectionSpritePosition;

typedef struct CollectionCharacterView { unsigned char _unknown_00[8]; void *vtable; int state; unsigned char _unknown_10[0xb0]; void *page_prompt_renderer; unsigned char _unknown_c4[0x34]; int transition_count; } CollectionCharacterView;

typedef struct CollectionTitleView { unsigned char _unknown_00[0x24]; void *title_renderer; } CollectionTitleView;

typedef struct CollectionDollDrawView { unsigned char _unknown_00[0x28]; void *control_renderer; unsigned char _unknown_2c[0x74]; void *ready_owner; unsigned char _unknown_a4[0xc]; int state; } CollectionDollDrawView;

typedef struct CollectionDioramaDrawView { unsigned char _unknown_00[0x24]; void *control_renderer; unsigned char _unknown_28[0x88]; void *ready_owner; struct CollectionPlaqueView *title_record; int controls_visible; int state; } CollectionDioramaDrawView;

typedef struct FrontendRectangle { short u; short v; short width; short height; } FrontendRectangle;

typedef struct CollectionFooterView { unsigned char _unknown_00[0x2c]; void *prompt_renderer; int state; unsigned char _unknown_34[0xc]; int category; } CollectionFooterView;

typedef struct CcsGeneratorAction { unsigned char *cursor; CcsScenePlayTarget *primary_anchor; CcsScenePlayTarget *secondary_anchor; ParticleEmitter *emitter; int identifier; } CcsGeneratorAction;

typedef struct CcsGeneratorActionManager { ParticleManager *owner; CcsActionRunner *runners; unsigned char transfer_owner; unsigned char _unknown_0009[3]; } CcsGeneratorActionManager;

typedef struct TextExtentResult { int character_count; float width; int widest_line_character_count; float widest_line_width; int line_break_count; } TextExtentResult;

typedef struct TextToken { int kind; int prefix_length; } TextToken;

typedef struct SpBattleHelpOwnerView { unsigned char _unknown_0000[0x10]; UiScrollingStrip *help; unsigned char _unknown_0014[0xe]; char text_buffer[1]; unsigned char _unknown_0023[0xff]; unsigned char request_flags; } SpBattleHelpOwnerView;

typedef struct AttachmentParameters { float velocity_retention; float length_correction; float shape_attraction; short child_index; unsigned char _unknown_000e[2]; } AttachmentParameters;

typedef struct AttachmentCollisionParameters { float translation[3]; float axis_scale[3]; short child_index; unsigned char _unknown_001a[2]; } AttachmentCollisionParameters;

typedef struct AttachmentState { float rest_local_matrix[16]; float rest_direction[4]; float current_point[4]; float previous_point[4]; float velocity[4]; CcsScenePlayTarget *scene_child; float rest_length; float velocity_retention; float length_correction; float shape_attraction; unsigned char collision_corrected; unsigned char _unknown_0095[3]; struct AttachmentState *first_child; struct AttachmentState *next; } AttachmentState;

typedef struct AttachmentChain { float local_anchor[4]; CcsScenePlayTarget *anchor; AttachmentState *states; struct AttachmentChain *next; unsigned char _unknown_001c[4]; } AttachmentChain;

typedef struct AttachmentCollision { float world_matrix[16]; float inverse_matrix[16]; float local_matrix[16]; CcsScenePlayTarget *scene_child; unsigned char correction_flags; unsigned char _unknown_00c5[3]; struct AttachmentCollision *next; unsigned char _unknown_00cc[4]; } AttachmentCollision;

typedef struct AttachmentManager { AttachmentChain *chains; AttachmentCollision *collisions; unsigned char rebase_requested; unsigned char _unknown_0009[3]; } AttachmentManager;

typedef struct AttachmentHierarchyNode { struct AttachmentHierarchyNode *parent; struct AttachmentHierarchyNode *first_child; struct AttachmentHierarchyNode *next_sibling; struct AttachmentHierarchyNode *previous_sibling; CcsRecord *source_record; CcsScenePlayTarget *scene_child; AttachmentState *state; AttachmentParameters *authored_parameters; AttachmentParameters *effective_parameters; short child_index; unsigned char _unknown_0026[2]; } AttachmentHierarchyNode;

typedef struct AttachmentHierarchy { AttachmentHierarchyNode root; AttachmentHierarchyNode *nodes; int child_count; } AttachmentHierarchy;

typedef struct AttachmentBuildTraversal { void *callback; unsigned short _unknown_0004; unsigned char _unknown_0006[2]; AttachmentState **state_tail; AttachmentChain **chain_tail; } AttachmentBuildTraversal;

typedef struct BattleAttachmentOwner { struct BattleAttachmentVtable *vtable; unsigned char _unknown_0004[0x10]; Fighter *fighter; unsigned char _unknown_0018[0xc]; CcsCompositionInstance *composition; CcsScenePlayTarget *anchor; } BattleAttachmentOwner;

typedef struct BattleStateAttachmentOwner { struct BattleAttachmentVtable *vtable; unsigned char _unknown_0004[0x10]; Fighter *fighter; unsigned char _unknown_0018[0xc]; short previous_animation_slot; unsigned char _unknown_0026[2]; CcsCompositionInstance *composition; CcsScenePlayTarget *anchor; unsigned char refresh_anchor; } BattleStateAttachmentOwner;

typedef struct FighterAuxiliaryAttachmentView { unsigned char _unknown_0000[0xee0]; CcsCompositionInstance *composition; CcsScenePlayTarget *anchor; } FighterAuxiliaryAttachmentView;

typedef struct OscillatingCompositionOwner { CcsCompositionInstance *composition; float pose_phase_degrees; float force_phase_degrees; float child_scalar; float translation[4]; float base_rotation_x; unsigned char _unknown_0024[4]; float rotation_z; unsigned char _unknown_002c[4]; unsigned short flags; } OscillatingCompositionOwner;

typedef struct FukidasiRankOffset { int x; int y; } FukidasiRankOffset;

typedef struct FukidasiRecordMap { unsigned char code; unsigned char _unknown_01[3]; int record; } FukidasiRecordMap;

typedef struct FukidasiPairRecordMap { unsigned char code; unsigned char _unknown_01[3]; int first_record; int second_record; } FukidasiPairRecordMap;

typedef struct StageSelectRecord { int logical_id; int preview_index; BattleHudRectangle name_rectangle; } StageSelectRecord;

typedef struct BattleWorldMarkerView { short state; unsigned char _unknown_02[2]; int side; unsigned char _unknown_08[8]; float x; float y; unsigned char _unknown_18[0x18]; float pulse_angle; float opacity; } BattleWorldMarkerView;

typedef struct BattleHudSpriteRecord { short u; short v; short width; short height; short texture_slot; short color_index; } BattleHudSpriteRecord;

typedef struct VsJutsuSelectorView { int side; unsigned char _unknown_04[8]; int state; int selected_row; float open_progress; float transition_progress; float transition_offset; float pulse_angle; unsigned char _unknown_24[0x10]; int selected_character; unsigned char _unknown_38[8]; void *row_sprite; ProjectedTextGeometryView *arrow_sprite; } VsJutsuSelectorView;

typedef struct CommandMenuLayersView { unsigned char _unknown_00[0x44]; void *position_provider; void *sprites[7]; } CommandMenuLayersView;

typedef struct CcsCompositionListNode { struct CcsCompositionListNode *next; CcsCompositionInstance *composition; } CcsCompositionListNode;

typedef struct BattleAttachmentVtable { unsigned char _unknown_0000[0x20]; void *refresh_transform; } BattleAttachmentVtable;

typedef struct BattleResultsCloud { float x; float y; float speed; float width; float height; } BattleResultsCloud;

typedef struct BattleResultsSummaryView { unsigned char _unknown_0000[0x10]; short side; short state; unsigned short elapsed; unsigned char _unknown_0016[0xA]; BattleResultsCloud clouds[5]; unsigned char _unknown_0084[0x94]; void *footer_render_context; void *stamp_animation; unsigned char _unknown_0120[0x20]; void *details_sprite; void *prompt_sprite; unsigned char _unknown_0148[4]; void *shared_rank_sprite; unsigned char _unknown_0150[0xC]; unsigned char stamp_rank; unsigned char _unknown_015d[3]; int result_rank; } BattleResultsSummaryView;

typedef struct NinjaSongDetailsView { unsigned char _unknown_0000[4]; BtlRecordOwnerRow *rows; unsigned char _unknown_0008[8]; short side; short state; unsigned short elapsed; unsigned char _unknown_0016[0x2A]; void *font; unsigned char _unknown_0044[0x1C]; float scroll; float scroll_limit; } NinjaSongDetailsView;

typedef struct VictoryNameRectangle { short u; short v; short width; short height; float local_x; float local_y; float display_width; float display_height; } VictoryNameRectangle;

typedef struct VictoryPresentationOwnerView { unsigned char _unknown_00[0xc]; void *animation_players[3]; ProjectedTextGeometryView *name_sprite; ProjectedTextGeometryView *count_sprite; short state; short elapsed; short character_id; short win_count; unsigned char _unknown_28[8]; int resource_request; float name_displacement; float echo_scale[2]; float echo_opacity[2]; unsigned char echo_enabled[2]; unsigned char _unknown_4a[2]; } VictoryPresentationOwnerView;

typedef struct BattleVictoryNameView { unsigned char _unknown_0000[0x3c8]; VictoryNameRectangle first_name; VictoryNameRectangle second_name; } BattleVictoryNameView;

typedef struct UiTextDrawRecord { float x; float y; char *text; unsigned int indexed_color; } UiTextDrawRecord;

typedef struct CollectionExitConfirmationView { unsigned char _unknown_0000[4]; UiPanel *body_panel; FrontEndModal *choice_panel; } CollectionExitConfirmationView;

typedef struct VsConfirmationPromptView { unsigned char _unknown_00[4]; int participant_choices[2]; unsigned char _unknown_0c[8]; void *selection_sprite; void *footer_sprite; unsigned char _unknown_1c[0x1c]; int alternate_prompt_enabled; int practice_prompt_enabled; } VsConfirmationPromptView;

typedef struct CommandScrollIndicatorView { unsigned char _unknown_00[0xc]; unsigned char pulse_rising; unsigned char _unknown_0d[3]; float pulse_offset; short pulse_count; } CommandScrollIndicatorView;

typedef struct MoveChartRow {
    char *name;
    unsigned char condition_index;
    unsigned char category_index;
    unsigned char _unknown_06[2];
    int tokens[10];
    int last_token_index;
} MoveChartRow;

typedef struct MoveChartView {
    unsigned char _unknown_00[0xC];
    int side;
    unsigned char _unknown_10[0xC];
    Fighter *fighter;
    int binding_tokens[4];
    unsigned char _unknown_30[4];
    short row_count;
    short scroll;
    short visible_rows;
    short scroll_direction;
    short row_y;
    short row_offset;
    MoveChartRow rows[1]; // partial view; no row-capacity claim
} MoveChartView;

typedef struct FighterMarkerControlView { unsigned char _unknown_00[0x60]; unsigned short packed_control_flags; } FighterMarkerControlView;

typedef struct FontResourceHeader { unsigned short type; unsigned char _unknown_02[6]; } FontResourceHeader;

typedef struct FontPaletteRecord { char filename[32]; unsigned int rgba[16]; } FontPaletteRecord;

typedef struct FontRasterDescriptor { unsigned char output_width; unsigned char output_height; unsigned char cell_width; unsigned char cell_height; unsigned char _unknown_04[2]; unsigned short glyph_stride; int glyph_count; int code_map_count; unsigned char *glyph_bytes; void *code_map; struct FontGlyphMetrics *metrics; } FontRasterDescriptor;

typedef struct FontRasterAsset { char filename[32]; unsigned char flags; unsigned char _unknown_21[3]; FontRasterDescriptor *descriptors; } FontRasterAsset;

typedef struct FontResource { struct FontResource *previous; struct FontResource *next; unsigned char _unknown_08[0x10]; FontRasterAsset *raster; unsigned char from_archive; unsigned char _unknown_1d[3]; void *clut; FontPaletteRecord *palette; } FontResource;

typedef struct FontAssetRendererView { unsigned char _unknown_00[0x58]; FontRasterAsset *ruby; FontRasterAsset *raster; FontPaletteRecord *palette; } FontAssetRendererView;

typedef struct FieldItemNameRow { unsigned int item_code; /* +0x00, stored u32 code; index scanner compares its low byte */ char *name; /* +0x04, resident Shift-JIS title with ruby markup */ } FieldItemNameRow;

typedef struct FontGlyphMetrics { unsigned char left_margin; unsigned char top_margin; unsigned char right_margin; unsigned char bottom_margin; } FontGlyphMetrics;

typedef struct PracticeCompletionView { unsigned char _unknown_00[8]; ActionRecord *completed_move; unsigned char _unknown_0c[0x48]; void *render_context; unsigned char _unknown_58[8]; void *panel_sprite; void *ok_sprite; unsigned char _unknown_68[0x24]; short font_transform; unsigned char _unknown_8e[2]; float panel_opacity; float fade_progress; float ok_scale; int shake_count; } PracticeCompletionView;

typedef struct CollectionPlaqueView { int title_enabled; unsigned char _unknown_04[0xC]; float x; float y; unsigned char _unknown_18[8]; char *title; } CollectionPlaqueView;

typedef struct BattlePromptRectangle { unsigned short u; unsigned short v; unsigned short width; unsigned short height; } BattlePromptRectangle;

typedef struct ModalYesNoDrawView { unsigned char _unknown_0000[0x1c]; void *render_context; } ModalYesNoDrawView;

typedef struct StageLineChangeTransition {
    short section;
    short source_line;
    short destination_line;
} StageLineChangeTransition;

typedef struct StageLineChangeRule {
    short load_slot;
    unsigned short _pad_0002;
    StageLineChangeTransition *transitions;
    short transition_count;
    unsigned short _pad_000A;
} StageLineChangeRule;

typedef struct AudioStreamFade { unsigned char flags; unsigned char seconds; unsigned short ratio; short target; short step; int _unknown_08; } AudioStreamFade;
