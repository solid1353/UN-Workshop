typedef struct Nun3CcsContainer {
    unsigned char _pad_0000[0x20C];
    unsigned short version;
} Nun3CcsContainer;

typedef struct Nun3TaskRecord { unsigned char _unknown_0000[4]; short thread_id; unsigned char _unknown_0006[2]; unsigned int runtime_flags; unsigned char _unknown_000C[4]; int wake_gate; unsigned char _unknown_0014[0x3C]; } Nun3TaskRecord;

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

typedef struct Nun3CharacterAnimationRow { short animation_slot; short duration; short start_frame; unsigned short rate; unsigned short motion_flags; short motion_event; float planar_speed; float vertical_speed; float motion_decay; float motion_multiplier; unsigned int bank1_flags; short bank1_start; short bank1_end; float bank1_radius; char *skeleton_object_name; float bank1_offset_x; float bank1_offset_z; unsigned int bank2_flags; short bank2_start; short bank2_end; float bank2_radius; char *bank2_skeleton_object_name; float bank2_offset_x; float bank2_offset_z; } Nun3CharacterAnimationRow;

typedef struct Nun3CharacterRecord { int character_id; char *display_name; char *body_filename; void *palette_names /* contiguous name records, 30 chars per record */; void *texture_names /* contiguous name records, 30 chars per record */; void *model_names /* contiguous name records, 30 chars per record */; char *effect_anchor_name; void *callbacks; unsigned char _unknown_0020[8]; int action_count; Nun3ActionRecord *default_actions; Nun3ActionRecord *alternate_actions; unsigned char _unknown_0034[4]; int row_count; Nun3CharacterAnimationRow *default_rows; Nun3CharacterAnimationRow *working_rows; int animation_count; char **animation_names; void **animation_working_array; unsigned char _unknown_0050[0x8c]; } Nun3CharacterRecord;

typedef struct Nun3FighterAssets { unsigned char _unknown_0000[0x30]; float position[4]; float orientation[4]; unsigned char _unknown_0050[0x14]; int character_id; unsigned char _unknown_0068[0x18]; Nun3CharacterRecord record; unsigned char _unknown_015c[0x1c]; short jutsu_selector[2]; unsigned char _unknown_017c[4]; short major_state; unsigned char _unknown_0182[2]; short phase; unsigned char _unknown_0186[0x802]; short action_count; short alternate_action_count; short current_action; unsigned char _unknown_098e[0x16]; Nun3ActionRecord *actions; unsigned char _unknown_09a8[0x12c]; unsigned int particle_colour; } Nun3FighterAssets;

typedef struct Nun3ActionRecord { char *debug_name; unsigned char _unknown_0004[4]; char *display_name; unsigned short owner_character; short jutsu_selector; unsigned char _unknown_0010[0x10]; float cost; unsigned char _unknown_0024[0x30]; } Nun3ActionRecord;

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

typedef struct Nun3CcsModelDescriptor { void *record; unsigned char _unknown_0004[0x40]; float position_scale; unsigned char _unknown_0048[8]; unsigned int header_color_word; unsigned char _unknown_0054[0xa]; unsigned short part_count; } Nun3CcsModelDescriptor;

typedef struct Nun3StageRecord { char * label; unsigned int type; char * primary_resource; char * secondary_resource; char * tertiary_resource; char * tokens; int parameter_a; int parameter_b; } Nun3StageRecord;

typedef struct Nun3SummonSceneRow { int mapping_index; int character_id; int scene_index; int reserved_zero; } Nun3SummonSceneRow;

typedef struct Nun3StageVector { unsigned int capacity; int count; void ** items; } Nun3StageVector;

typedef struct Nun3StageNode { float position[4]; unsigned char _unknown_0010[0x10]; } Nun3StageNode;

typedef struct Nun3StageControl { unsigned char _unknown_0000[0x6a]; unsigned short doll_node_count; unsigned char fade_out; unsigned char _unknown_006d[0x3]; float fade; unsigned char updates_blocked; unsigned char _unknown_0075[0x17]; int scene_index; unsigned char _unknown_0090[0x128]; unsigned int fog_rgb; float fog_near; float fog_far; float fog_far_percent; float fog_near_percent; unsigned char _unknown_01cc[0x4]; Nun3StageNode * doll_nodes; unsigned char * doll_node_flags; unsigned char _unknown_01d8[0x44]; void * background_bullet; void * object_bullet; unsigned char _unknown_0224[0x4]; void * base_model; void * archive; unsigned char _unknown_0230[0x10]; Nun3StageVector far_objects; Nun3StageVector base_objects; Nun3StageVector animation_props; Nun3StageVector creature_props; Nun3StageVector reactive_props; Nun3StageVector category9_objects; Nun3StageVector transparent_objects; Nun3StageVector * object_lists[7]; unsigned char _unknown_02b0[0x980]; unsigned int update_restrictions; unsigned char _unknown_0c34[0x6c]; void *vtable; } Nun3StageControl;

typedef struct Nun3StageObject { unsigned char disabled; unsigned char _unknown_0001[0x3]; void * archive; void * secondary_model; char * animation_name; unsigned char _unknown_0010[4]; void *self; unsigned char _unknown_0018[4]; char *label; unsigned short subtype; unsigned char _unknown_0022[0x2]; int status; unsigned char updates_when_restricted; unsigned char _unknown_0029[0x3]; void * model; int initialization_category; void * vtable; } Nun3StageObject;

typedef struct Nun3StageAnimationObject { Nun3StageObject base; unsigned char child_parameter_enabled; } Nun3StageAnimationObject;

typedef struct Nun3StageRotatingSky { Nun3StageObject base; float angular_speed; unsigned char _unknown_003c[0x4]; float rotation[4]; } Nun3StageRotatingSky;

typedef struct Nun3StageModelAnimation { unsigned char _unknown_0000[0x88]; float frame_value; unsigned char _unknown_008c[4]; void *animation; unsigned short playback_step; unsigned short frame_fraction; unsigned int frame_index; unsigned char _unknown_009c[0x14]; unsigned int frame_position; } Nun3StageModelAnimation;

typedef struct Nun3StageGlareEffect { unsigned char _unknown_0000[0x81]; unsigned char mode; unsigned char _unknown_0082[0x2]; unsigned int primary_colour; float amount; unsigned int secondary_colour; } Nun3StageGlareEffect;

typedef struct Nun3StageGlareObject { Nun3StageObject base; Nun3StageGlareEffect * effect; } Nun3StageGlareObject;

typedef struct Nun3StageWire { Nun3StageObject base; unsigned char _unknown_0038[0x2c]; int segment_count; unsigned char _unknown_0068[0x78]; float first_endpoint[4]; float second_endpoint[4]; } Nun3StageWire;

typedef struct Nun3StageTransparentObject { Nun3StageObject base; unsigned char _unknown_0038[0x48]; float hit_position[4]; unsigned char _unknown_0090[0x20]; float node_position[4]; float blend; float frame_override; int contact_divisor; } Nun3StageTransparentObject;

typedef struct Nun3StageBridge { Nun3StageObject base; unsigned char _unknown_0038[0x4]; void * segment_models; void * rope_helpers; void * segment_helpers; float parameter_8; float parameter_9; unsigned char parameter_10; } Nun3StageBridge;

typedef struct Nun3StageBreakable { Nun3StageObject base; unsigned char contact; unsigned char _unknown_0039[0x1]; short reaction_pending; unsigned char _unknown_003c[4]; float model_position[4]; float contact_position[4]; float shape_width; float shape_height; unsigned char shape_count; unsigned char _unknown_0069[0xb]; int configured_count; int remaining_count; unsigned char _unknown_007c[4]; float pulse; int effect_parameter_a; int effect_parameter_b; unsigned char debris_active; unsigned char _unknown_008d[0x3]; void * debris; int configured_pose_or_sequence; char * damaged_animation; char * broken_animation; unsigned char _unknown_00a0[0x8]; void * attack_contact; unsigned char _unknown_00ac[0x1c]; void * receiver_contact; unsigned char _unknown_00cc[0x64]; void * shape_storage; unsigned char render_contact_latched; unsigned char _unknown_0135[7]; unsigned char contact_side; unsigned char _unknown_013d[3]; } Nun3StageBreakable;

typedef struct Nun3StageLantern { Nun3StageBreakable base; float configured_amplitude; float amplitude; int phase; float sample; unsigned char _unknown_0150[4]; int contact_value_30; unsigned char effect_mode; } Nun3StageLantern;

typedef struct Nun3StageWindBell { Nun3StageBreakable base; float configured_amplitude; float amplitude; int phase; float sample; unsigned char _unknown_0150[8]; int contact_value_30; } Nun3StageWindBell;

typedef struct Nun3StageTrainingDoll { Nun3StageBreakable base; int scene_index; unsigned char _unknown_0144[0x4]; char * appear_animation; char * normal_animation; char * final_animation; unsigned char _unknown_0154[0x8]; int elapsed; int delay; int configured_sequence; int delay_base; unsigned char _unknown_016c[0x4]; Nun3StageNode * prepared_node; unsigned char _unknown_0174[0xc]; } Nun3StageTrainingDoll;

typedef struct Nun3StageContactDescriptor { unsigned char _unknown_0000[0x10]; unsigned int flags; unsigned int secondary_flags; } Nun3StageContactDescriptor;

typedef struct Nun3StageContactShape { unsigned char _unknown_0000[0x18]; float extent; float offset; } Nun3StageContactShape;

typedef struct Nun3StageBattleContext { unsigned char flags; unsigned char request_flags; unsigned char _unknown_0002[0x5a]; int scene_class; unsigned char _unknown_0060[1]; unsigned char scene_index; unsigned char _unknown_0062[0x19]; unsigned char pending_scene; unsigned char summon_side_plus_one; unsigned char saved_scene; unsigned char _unknown_007e[0x8e2]; int transition_reason; unsigned char _unknown_0964[0xc8]; void *restriction_owner; } Nun3StageBattleContext;

typedef struct Nun3StageRestrictionOwner { unsigned char _unknown_0000[0x10]; unsigned char restriction_byte; unsigned char _unknown_0011[0x9e7]; short restriction_9f8; unsigned char _unknown_09fa[4]; short restriction_9fe; unsigned char _unknown_0a00[0xa0]; short restriction_aa0; unsigned char _unknown_0aa2[4]; short restriction_aa6; } Nun3StageRestrictionOwner;

typedef struct Nun3StagePulseContext { unsigned char _unknown_0000[1]; unsigned char pacing; unsigned char _unknown_0002[0x196]; int pulse_counter; } Nun3StagePulseContext;

typedef struct Nun3StageObjectVtable { unsigned char _unknown_0000[8]; void *initialize; void *auxiliary; void *update; void *draw; void *destroy; void *trigger; } Nun3StageObjectVtable;

typedef struct Nun3SummonSequence { unsigned char _unknown_0000[0x16]; short counter; } Nun3SummonSequence;

typedef struct Nun3StageAnimationDescriptor { unsigned char _unknown_0000[0x10]; int frame_count; unsigned char _unknown_0014[0x18]; unsigned short flags; } Nun3StageAnimationDescriptor;

typedef struct Nun3StageLanternContactEntity { unsigned char _unknown_0000[0x8e0]; short phase_selector; } Nun3StageLanternContactEntity;

typedef struct Nun3CharacterDefinition { void *factory; Nun3CharacterRecord *record; } Nun3CharacterDefinition;

typedef struct Nun3ItemSlot { unsigned char occupied; unsigned char _unknown_0001[3]; int index; int item_code; int count; float list_position; float animated_position; int animation_state; int animation_auxiliary; } Nun3ItemSlot;

typedef struct Nun3ItemCacheEntry { int item_code; unsigned char count; unsigned char _unknown_0005[3]; } Nun3ItemCacheEntry;

typedef struct Nun3ItemPanel { unsigned char _unknown_0000[0x2c]; Nun3ItemSlot *slots[5]; int selected_slot; int side; int occupied_count; unsigned char _unknown_004c[4]; float position[4]; float base_position[4]; float scroll; unsigned char _unknown_0074[0x1c]; } Nun3ItemPanel;

typedef struct Nun3ItemManager { unsigned char _unknown_0000[0x84]; Nun3ItemPanel *panels[2]; } Nun3ItemManager;

typedef struct Nun3ItemLayoutPoint { float x; float y; unsigned char _unknown_0008[8]; } Nun3ItemLayoutPoint;

typedef struct Nun3StageCameraRecord { float eye_decreasing; float eye_increasing_large; float eye_increasing_medium; float eye_increasing_small; float unknown_10; float target_same_section; float unknown_18; float target_large; float target_medium; float target_small; float min_distance; float max_distance; float target_upper; float target_lower; float edge_upper; float edge_lower; float eye_height_cap; float unknown_44; float eye_lateral_scale; float differing_section_elevation; float same_nonzero_section_elevation; float spread_control; float unknown_58; float unknown_5c; } Nun3StageCameraRecord;

typedef struct Nun3StageAnchorRecord { float *side0; float *side1; unsigned char counts[2]; unsigned char unknown_0a[6]; } Nun3StageAnchorRecord;

typedef struct Nun3StageRouteRecord { signed char source_line; signed char destination_line; unsigned char unknown_02[2]; float point_fraction; unsigned char action_type; unsigned char unknown_09[3]; } Nun3StageRouteRecord;

typedef struct Nun3GuyHairState { int mode; void *head_node; void *body_node; void *hair_models[2]; } Nun3GuyHairState;

typedef struct Nun3UltimateJutsuRecord { char *display_name; short authored_id; short ability_count; short ability_ids[3]; unsigned char _unknown_000e[4]; short intro_voice; unsigned short effect; short damage_percent; short stat_adjustments[6]; } Nun3UltimateJutsuRecord;

typedef struct Nun3SkillRequestRow { char *display_name; char *main_path; unsigned char extra_count; unsigned char stream_count; unsigned char _unknown_000a[2]; char **extra_paths; void *stream_pairs; } Nun3SkillRequestRow;
