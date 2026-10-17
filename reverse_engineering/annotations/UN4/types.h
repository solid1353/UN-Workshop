typedef struct un4ItemSlot { unsigned char occupied; unsigned char _unknown_0001[3]; int index; unsigned char item_code; unsigned char _unknown_0009[3]; int count; float list_position; float animated_position; unsigned char animation_state; unsigned char _unknown_0019[3]; int animation_auxiliary; } un4ItemSlot;

typedef struct un4ItemBadge { int side; int sprite_id; unsigned char _unknown_0008[8]; float position[4]; float offset[4]; float press_scale; unsigned char binding_selector; unsigned char _unknown_0035[0xb]; } un4ItemBadge;

typedef struct un4ItemPanel { unsigned char _unknown_0000[0x10]; un4ItemBadge *first_badge; un4ItemBadge *second_badge; unsigned char _unknown_0018[0xc]; un4ItemSlot *slots[5]; int selected_slot; int side; int occupied_count; unsigned char _unknown_0044[0xc]; float position[4]; float base_position[4]; float scroll; } un4ItemPanel;

typedef struct un4ItemLayoutPoint { float x; float y; unsigned char _unknown_0008[8]; } un4ItemLayoutPoint;

typedef struct un4StageCameraRecord { float eye_decreasing; float eye_increasing_large; float eye_increasing_medium; float eye_increasing_small; float unknown_10; float target_same_section; float unknown_18; float target_large; float target_medium; float target_small; float min_distance; float max_distance; float target_upper; float target_lower; float edge_upper; float edge_lower; float eye_height_cap; float unknown_44; float eye_lateral_scale; float differing_section_elevation; float same_nonzero_section_elevation; float spread_control; float unknown_58; float unknown_5c; } un4StageCameraRecord;

typedef struct un4StageAnchorRecord { float *side0; float *side1; unsigned char counts[2]; unsigned char unknown_0a[6]; } un4StageAnchorRecord;

typedef struct un4StageRouteRecord { signed char source_line; signed char destination_line; unsigned char unknown_02[2]; float point_fraction; unsigned char action_type; unsigned char unknown_09[3]; } un4StageRouteRecord;

typedef struct un4TsunadeDescriptor { unsigned int character_record; unsigned char _unknown_0004[0x4C]; int mode0_action_indices[3]; unsigned char _unknown_005c[4]; int mode1_action_indices[4]; int audio_range_start; int audio_range_end; int audio_event; } un4TsunadeDescriptor;

typedef struct un4ActionRecord { char *debug_name; char *auxiliary_name; char *display_names[5]; unsigned short owner_character; short jutsu_selector; unsigned int category; unsigned int flags; signed char continuation; unsigned char _unassigned_0029[3]; unsigned int signature; float cost; unsigned char _unassigned_0034[0x10]; float threshold; float threshold_2; unsigned char _unassigned_004c[0x14]; int row; } un4ActionRecord;

typedef struct un4FighterControlBlock { short value_00; short value_02; short value_04; short value_06; short value_08; short value_0a; short value_0c; short value_0e; short value_10; short value_12; short value_14; short value_16; } un4FighterControlBlock;

typedef struct un4UltimateJutsuRecord { char *display_name; unsigned short authored_id; short category; unsigned char record_class; signed char cost_tier; short intro_voice; unsigned short effect; short damage_percent; } un4UltimateJutsuRecord;

typedef struct un4SpSkillRequestRow { char *display_name; char *main_path; unsigned char extra_count; unsigned char stream_count; unsigned char unknown_0a[2]; char **extra_paths; char **stream_path_pairs; } un4SpSkillRequestRow;

typedef struct un4UltimateJutsuHitRow { short frame; signed char popup; signed char sound; unsigned short damage_fraction; unsigned short chakra_fraction; } un4UltimateJutsuHitRow;

typedef struct un4UltimateJutsuHitDescriptor { int count; un4UltimateJutsuHitRow *rows; } un4UltimateJutsuHitDescriptor;

typedef struct un4ReversalDefinition { int entry_index; int character_id; int resource_index; int unknown_0c; } un4ReversalDefinition;

typedef struct un4OrochimaruSwordState { float active; float extent; float target_extent; float smoothing_duration; float query_parameter0; float query_parameter1; } un4OrochimaruSwordState;

typedef struct un4SpSkillPaletteRow { char *source_container_name; char *target_name; char *source_palette_name; } un4SpSkillPaletteRow;

typedef struct un4SpSkillPaletteDescriptor { un4SpSkillPaletteRow **rows; int count; } un4SpSkillPaletteDescriptor;

typedef struct un4SpSkillDefenderOffsetHeader { char magic[8]; unsigned short version; short phase_count; short defender_count; short phase_frames[1]; } un4SpSkillDefenderOffsetHeader;

typedef struct un4CcfmHeader { char magic[4]; unsigned short version; unsigned short unused_06; } un4CcfmHeader;

typedef struct un4CcfmBankHeader { unsigned short interval_count; unsigned short record_count; } un4CcfmBankHeader;
