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

// Character action record; also the attack record of a hit. 0x54 bytes.
typedef struct ActionRecord {
    char *debug_name; // always the empty string in retail data
    unsigned char _pad_0004[0x4];
    char *display_name; // Shift-JIS move name
    unsigned char _pad_000C[0x4];
    unsigned int category; // 0x2 fixed slot 19 and forced lock, 0xF000 chain group, 0xF0000 hold/companion, 0xF00000 jutsu
    unsigned int flags; // 0x380 mode-1 group, 0x1C00 exchange group, 0x20000 no attacker pause, 0x80000/0x100000 contact rebound, 0x200000 rehit bypass, 0x400000/0x800000 guard bypass
    signed char continuation; // -1 immediate, -2 chain/any, else required current action index
    unsigned char streak_exempt; // zero lets a long receiver streak force response 0x37
    unsigned char _pad_001A[0x2];
    unsigned int signature; // normalized input signature
    float cost; // chakra cost
    unsigned char _pad_0024[0x4];
    float knockback_scale; // copied to Fighter.attack_scale
    unsigned char response_selector; // ordinary-response selector; 0xFF on non-damaging records
    signed char guard_selector; // guarded-response row 0..9
    short repeat_count; // expected hit count; copied to Fighter.attack_repeat_countdown
    short update_pause; // positive staged, negative immediate, 0x7FFF use the response row
    short rejection_count; // positive staged, negative immediate, 0x7FFF use the response row
    float threshold; // contextual threshold; -17320.508 resolved at setup
    float threshold_2; // second threshold; same sentinel
    unsigned char _pad_003C[0x14];
    int row; // row index into a 0x4C-byte table, converted to a pointer at setup
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

// Resident pad record; 0x78 bytes per side.
typedef struct PadRecord {
    unsigned char _pad_0000[0x49];
    unsigned char left_magnitude;
    unsigned char right_magnitude;
    unsigned char _pad_004B[0x1];
    float left_angle; // radians
    float right_angle; // radians
    unsigned char _pad_0054[0x10];
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

// Battle fighter. Fields from the hit-response and action-command research.
typedef struct Fighter {
    unsigned char _pad_0000[0x20];
    struct Fighter *opponent; // paired fighter
    struct BattleInput *input; // battle input object
    unsigned char _pad_0028[0x8];
    float position[4];
    float orientation[4]; // +0x08 is the yaw used by the view-relative input angle
    unsigned char _pad_0050[0x10];
    unsigned char control_flags; // with state_flags read as one halfword, bits 5..8 suppress logical input
    unsigned char state_flags; // 0x08 timed downed recovery enabled; 0x80 fixed hit gravity
    unsigned char status_flags; // 0x01 no statistics, no exchange; 0x20 slow downed profile
    unsigned char contact_flags; // 0x01 routed this update, 0x40 side contact, 0x80 grounded
    unsigned char ceiling_flags; // 0x01 ceiling contact
    unsigned char _pad_0065[0x17];
    float staged_chakra; // staged chakra amount for jutsu selection
    short staged_tier;
    unsigned char _pad_0082[0x36];
    ActionRecord *default_actions; // character's default action array
    unsigned char _pad_00BC[0x3C];
    float motion_scale; // native motion scalar; recovery impulses use 3 * this as gravity
    unsigned char _pad_00FC[0x4];
    float recovery_planar_speed; // ACT_RCV_0 planar target
    unsigned char _pad_0104[0x4C];
    float knockback_taken; // receiver factor, clamped to 0..2
    float knockback_given; // source factor
    unsigned char _pad_0158[0x2C];
    short jutsu_selector[2]; // configured jutsu selectors for records 0..3
    short jutsu_slot_config; // retained slot among 4..9
    unsigned char _pad_018A[0x4];
    short major_state; // 5 ordinary hit, 6 timed downed recovery, 8 action
    short substate; // ordinary response 0x27..0x5C, downed 0x5D..0x62, guard 5..7
    short phase; // phase within the current action
    unsigned char _pad_0194[0x18];
    float update_rate; // advances the timelines and the action lock; 1.0 in majors 5 and 6 unless overridden
    float update_rate_override; // replaces the effect factor when not 1.0
    float update_rate_multiplier; // multiplies update_rate when not 1.0
    TimelineBlock primary_timeline; // action cursor; zeroed on state entry
    TimelineBlock secondary_timeline; // advances at update_rate * secondary_rate
    TimelineBlock update_pause; // decrements by 1.0; positive suspends action updates
    TimelineBlock hit_rejection; // decrements by 1.0 without a pause; positive makes router modes 0, 2, 3 discard hits
    TimelineBlock action_lock; // decrements by update_rate after the pause; action entry waits for zero
    unsigned char _pad_026C[0xBA];
    short facing; // 1 swaps requested Right/Left in ccCommand matching
    unsigned char _pad_0328[0x10];
    unsigned int logical_input; // copied from BattleInput.logical_mask
    float stick_magnitude;
    float stick_angle;
    InputSample input_history[32]; // appended after the timelines advance
    int input_history_index;
    unsigned char _pad_04C8[0x28];
    StatPair stats[24]; // 12 input recoveries, 18 ordinary hits, 19 guarded hits
    unsigned char _pad_0550[0x278];
    void *recovery_source; // retained recovery source; not cleared by response exits
    ActionRecord *recovery_record; // retained recovery record
    unsigned char _pad_07D0[0x60];
    unsigned char recovery_grounded; // grounding saved with the recovery source
    unsigned char _pad_0831[0x93];
    int effect_count;
    void *effects; // effect nodes; ID at +0x68, countdown at +0x6C
    unsigned char _pad_08CC[0x4C];
    short input_params_shadow[12]; // copy of the hold/release and multi-press parameters
    unsigned char _pad_0930[0x2A];
    short guard_state; // below 1 ordinary response, 1 or more guarded response, -1 guard bypass
    short guard_input_timing;
    short guard_response_index; // guarded-response row
    short response_4f_stage; // private stage of response 0x4F
    short response_4f_stage_count; // per-stage invocation count of response 0x4F
    unsigned char _pad_0964[0x2C];
    short response_facing;
    unsigned char _pad_0992[0x2];
    float response_planar_speed; // oriented planar speed
    float response_vertical_speed;
    unsigned char _pad_099C[0x4];
    float attack_scale; // attack knockback scale; reset to 1.0 after use
    float saved_attack_scale; // attack_scale saved at the motion event
    float planar_scale; // transient planar scale; reset to 1.0 after use
    float vertical_scale; // transient vertical scale; reset to 1.0 after use
    float landing_vertical_speed; // vertical speed saved on first grounding
    float next_gravity; // gravity for the next movement pass; reset to 1.0 after it
    unsigned char _pad_09B8[0x3E];
    short section; // stage section
    unsigned char _pad_09F8[0x38];
    void *action_descriptor; // current action-descriptor row
    unsigned char _pad_0A34[0x4];
    short action_count;
    unsigned char _pad_0A3A[0x2];
    short current_action; // current action index
    short pending_action; // one pending action index; -1 empty
    unsigned char action_outcome;
    unsigned char _pad_0A41[0xB];
    ActionRecord *current_record; // current action record
    unsigned char _pad_0A50[0x4];
    ActionRecord *actions; // working action array
    unsigned char _pad_0A58[0x88];
    float saved_response_position[4]; // restored by the held-response handoff
    unsigned char _pad_0AF0[0x10];
    unsigned int exchange_roles; // Extra Hit exchange roles; 0x100/0x400/0x1000 select modes 2 and 3
    unsigned char _pad_0B04[0x6];
    short exchange_window; // interval for the opposite fighter's window progress
    float exchange_progress; // cached window progress
    unsigned char _pad_0B10[0x24];
    short queued_chain; // retained direct-action chain; -1 none
    unsigned char _pad_0B36[0xA];
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
    unsigned char _pad_0B70[0x14];
    void **animations; // animation objects indexed by phase-record slot
    unsigned int animation_result; // nonzero once the animation ends
    short animation_slot; // current animation slot
    unsigned char _pad_0B8E[0x2];
    unsigned short secondary_rate; // secondary timeline and animation rate, /256
    unsigned char _pad_0B92[0x2];
    short animation_start_frame;
    unsigned char _pad_0B96[0x4];
    short grounded_updates; // consecutive grounded updates; zero while airborne
    unsigned char ground_air_history; // 1 entered grounded, 2 entered airborne; 0x20/0x10 later changes
    unsigned char _pad_0B9D[0x2B7];
    ActionRecord *response_attack_record; // attack record of the active response
    void *response_source; // source object of the active response
    short attack_repeat_countdown; // retained repeat count from the attack record
} Fighter;

// Battle input object (original class ccCommand); 0xC0 bytes.
typedef struct BattleInput {
    unsigned char _pad_0000[0x14];
    char *identifier; // controller1 for side 0, controller2 for side 1
    unsigned char _pad_0018[0x8];
    Fighter *fighter; // owning fighter
    Fighter *opponent; // other fighter, for relative angles
    unsigned char _pad_0028[0x38];
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
