typedef struct Nun4ItemSlot { unsigned char occupied; unsigned char _unknown_0001[3]; int index; unsigned char item_code; unsigned char _unknown_0009[3]; int count; float list_position; float animated_position; unsigned char animation_state; unsigned char _unknown_0019[3]; int animation_auxiliary; } Nun4ItemSlot;

typedef struct Nun4ItemBadge { int side; int sprite_id; unsigned char _unknown_0008[8]; float position[4]; float offset[4]; float press_scale; unsigned char binding_selector; unsigned char _unknown_0035[0xb]; } Nun4ItemBadge;

typedef struct Nun4ItemPanel { unsigned char _unknown_0000[0x10]; Nun4ItemBadge *first_badge; Nun4ItemBadge *second_badge; unsigned char _unknown_0018[0xc]; Nun4ItemSlot *slots[5]; int selected_slot; int side; int occupied_count; unsigned char _unknown_0044[0xc]; float position[4]; float base_position[4]; float scroll; } Nun4ItemPanel;

typedef struct Nun4ItemLayoutPoint { float x; float y; unsigned char _unknown_0008[8]; } Nun4ItemLayoutPoint;

typedef struct Nun4StageCameraRecord { float eye_decreasing; float eye_increasing_large; float eye_increasing_medium; float eye_increasing_small; float unknown_10; float target_same_section; float unknown_18; float target_large; float target_medium; float target_small; float min_distance; float max_distance; float target_upper; float target_lower; float edge_upper; float edge_lower; float eye_height_cap; float unknown_44; float eye_lateral_scale; float differing_section_elevation; float same_nonzero_section_elevation; float spread_control; float unknown_58; float unknown_5c; } Nun4StageCameraRecord;

typedef struct Nun4StageAnchorRecord { float *side0; float *side1; unsigned char counts[2]; unsigned char unknown_0a[6]; } Nun4StageAnchorRecord;

typedef struct Nun4StageRouteRecord { signed char source_line; signed char destination_line; unsigned char unknown_02[2]; float point_fraction; unsigned char action_type; unsigned char unknown_09[3]; } Nun4StageRouteRecord;
