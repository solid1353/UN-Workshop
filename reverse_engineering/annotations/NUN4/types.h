typedef struct Nun4ItemSlot { unsigned char occupied; unsigned char _unknown_0001[3]; int index; unsigned char item_code; unsigned char _unknown_0009[3]; int count; float list_position; float animated_position; unsigned char animation_state; unsigned char _unknown_0019[3]; int animation_auxiliary; } Nun4ItemSlot;

typedef struct Nun4ItemBadge { int side; int sprite_id; unsigned char _unknown_0008[8]; float position[4]; float offset[4]; float press_scale; unsigned char binding_selector; unsigned char _unknown_0035[0xb]; } Nun4ItemBadge;

typedef struct Nun4ItemPanel { unsigned char _unknown_0000[0x10]; Nun4ItemBadge *first_badge; Nun4ItemBadge *second_badge; unsigned char _unknown_0018[0xc]; Nun4ItemSlot *slots[5]; int selected_slot; int side; int occupied_count; unsigned char _unknown_0044[0xc]; float position[4]; float base_position[4]; float scroll; } Nun4ItemPanel;

typedef struct Nun4ItemLayoutPoint { float x; float y; unsigned char _unknown_0008[8]; } Nun4ItemLayoutPoint;
