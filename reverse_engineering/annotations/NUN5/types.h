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

typedef struct AfsMetadataAllocation { void *buffer; unsigned int capacity; } AfsMetadataAllocation;

typedef struct AfsManager { unsigned char _unknown_0000[0xF4]; AfsMetadataAllocation top_level[4]; AfsMetadataAllocation sound_children[13]; AfsMetadataAllocation rpgvoice_children[82]; AfsMetadataAllocation plvoice_children[93]; unsigned char _unknown_06f4[8]; int group_counts[4]; unsigned char _unknown_070c[0xC]; } AfsManager;

typedef struct ActionNameView { unsigned char _unknown_0000[8]; union { char *direct_text; struct { unsigned short index; signed char group; unsigned char flags; } localized; } display_name; unsigned char matching_metadata[0x48]; } ActionNameView;

typedef struct MemoryCardWorkerView { unsigned char _unknown_0000[0x40]; int port; unsigned char _unknown_0044[4]; int operation; int status; int result_class; int mode; int preflight_result; } MemoryCardWorkerView;

typedef struct CardInfoView { int type; int free_blocks; int formatted; unsigned char _unknown_000C[8]; } CardInfoView;

typedef struct MemoryCardContextView { unsigned char _unknown_0000[0x410]; union { CardInfoView card_info[2]; struct { unsigned char _unknown_0410[0x24]; int expected_blocks; } capacity; } state; } MemoryCardContextView;

typedef struct NinjaSongArithmeticDescriptorView { short target; short unit_index; signed char comparison_index; unsigned char _unknown_0005[3]; char *text; } NinjaSongArithmeticDescriptorView;

typedef struct CollectionRosterRecord { char *display_name; unsigned char metadata[8]; } CollectionRosterRecord;

typedef struct CollectionUltimateRecord { char *display_name; unsigned int metadata[3]; } CollectionUltimateRecord;

typedef struct CollectionUltimateScreenRecord { unsigned int metadata[3]; char *display_name; } CollectionUltimateScreenRecord;

typedef struct CollectionVoiceRecord { char *display_name; unsigned int voice_id; unsigned int type; } CollectionVoiceRecord;

typedef struct FrontendRectangle { short u; short v; short width; short height; } FrontendRectangle;

typedef struct ScreenPositionView { unsigned char _unknown_00[0x1c]; short x_offset; short y_offset; } ScreenPositionView;

typedef struct FrontendFontSpacingView { unsigned char _unknown_00[0x3c]; float tracking; float extra_spacing; } FrontendFontSpacingView;

typedef struct CollectionSpritePosition { float x; float y; float z; float w; } CollectionSpritePosition;

typedef struct CollectionCharacterView { unsigned char _unknown_00[8]; void *vtable; int state; unsigned char _unknown_10[0xb0]; void *page_prompt_renderer; unsigned char _unknown_c4[0x34]; int transition_count; } CollectionCharacterView;

typedef struct CollectionTitleView { unsigned char _unknown_00[0x24]; void *title_renderer; } CollectionTitleView;

typedef struct CollectionDollDrawView { unsigned char _unknown_00[0x28]; void *control_renderer; unsigned char _unknown_2c[0x74]; void *ready_owner; unsigned char _unknown_a4[0xc]; int state; } CollectionDollDrawView;

typedef struct CollectionDioramaDrawView { unsigned char _unknown_00[0x24]; void *control_renderer; unsigned char _unknown_28[0x88]; void *ready_owner; struct CollectionPlaqueView *title_record; int controls_visible; int state; } CollectionDioramaDrawView;

typedef struct CollectionControllerVtable { void *type_info; unsigned int zero; void *delete_method; void *initialize_method; void *update_method; void *present_method; } CollectionControllerVtable;

typedef struct CollectionFooterView { unsigned char _unknown_00[0x2c]; void *prompt_renderer; int state; unsigned char _unknown_34[0xc]; int category; } CollectionFooterView;

typedef struct UiScrollSegment { unsigned char owns_string; unsigned char _unknown_0001[3]; char *string; float extent; struct UiScrollSegment *next; } UiScrollSegment;

typedef struct UiScrollingStrip { float viewport_width; float viewport_height; void *text_context; void *backing_context; void *backing_sprite; int textured_backing; float text_axis_offset; unsigned int text_color; unsigned int backing_color; unsigned char vertical; unsigned char _unknown_0025[3]; unsigned int text_opacity; UiScrollSegment *head; float distance; float speed; short delay; short elapsed_delay; unsigned char enqueue_inhibited; unsigned char minimum_first_extent; unsigned char _unknown_003e[2]; } UiScrollingStrip;

typedef struct UiScrollConfiguration { float x; float y; float width; float height; float text_axis_offset; unsigned int text_color; unsigned int backing_color; unsigned char vertical; unsigned char _unknown_001d[3]; float speed; } UiScrollConfiguration;

typedef struct TextExtentResult { int character_count; float width; int widest_line_character_count; float widest_line_width; int line_break_count; } TextExtentResult;

typedef struct TextToken { int kind; int prefix_length; } TextToken;

typedef struct RunningHelpFontView { unsigned char _unknown_0000[4]; float cell_width; float cell_height; unsigned int output_width; unsigned int output_height; float pen_x; float pen_y; float glyph_x; float glyph_y; unsigned char _unknown_0024[0x14]; unsigned int trailing_margin; float tracking; float line_extra; unsigned char _unknown_0044[0x10]; unsigned char alternate_orientation; unsigned char _unknown_0055[0x2b]; float horizontal_scale; float vertical_scale; float horizontal_space_extra; unsigned char _unknown_008c[0x40c]; void *font_descriptor; unsigned char _unknown_049c[8]; struct FontGlyphDescriptor *glyph_descriptor; unsigned char _unknown_04a8[4]; unsigned char render_flags; unsigned char _unknown_04ad[0xb]; void *icon_measure_callback; float start_x; float start_y; } RunningHelpFontView;

typedef struct RunningHelpViewportView { unsigned char _unknown_0000[0x284]; float viewport_left; float viewport_top; float viewport_width; float viewport_height; } RunningHelpViewportView;

typedef struct SpBattleHelpOwnerView { unsigned char _unknown_0000[0x10]; UiScrollingStrip *help; unsigned char _unknown_0014[0xe]; char text_buffer[1]; unsigned char _unknown_0023[0xff]; unsigned char request_flags; } SpBattleHelpOwnerView;

typedef struct Fukidasi { void *vtable; float display_x; float display_y; unsigned char code; unsigned char state; unsigned char _unknown_0e[6]; int callback_argument; int side; unsigned char _unknown_1c[4]; float position[4]; float opacity; float bubble_scale; int rank_x; int rank_y; float width_scale; struct Fukidasi *next; } Fukidasi;

typedef struct FukidasiNumeric { Fukidasi base; unsigned char _unknown_48[8]; int value; float digit_scale; } FukidasiNumeric;

typedef struct FukidasiList { Fukidasi *head; int side; } FukidasiList;

typedef struct FukidasiRankOffset { int x; int y; } FukidasiRankOffset;

typedef struct FukidasiRecordMap { unsigned char code; unsigned char _unknown_01[3]; int record; } FukidasiRecordMap;

typedef struct FukidasiPairRecordMap { unsigned char code; unsigned char _unknown_01[3]; int first_record; int second_record; } FukidasiPairRecordMap;

typedef struct ItemBattleSpriteRecord { unsigned char mode; unsigned char flags; unsigned short u; unsigned short v; unsigned short width; unsigned short height; unsigned char layer; unsigned char _unknown_0b; } ItemBattleSpriteRecord;

typedef struct ProjectedTextGeometryView { int disabled; unsigned int geometry_flags; unsigned char _unknown_0008[0x38]; float opacity; float local_x; float local_y; float rotation; float x; float y; float width; float height; int source_width; int source_height; int source_u_fixed4; int source_v_fixed4; int source_mode; } ProjectedTextGeometryView;

typedef struct VsJutsuSelectorView { int side; unsigned char _unknown_04[8]; int state; int selected_row; float open_progress; float transition_progress; float transition_offset; float pulse_angle; unsigned char _unknown_24[0x10]; int selected_character; unsigned char _unknown_38[8]; void *row_sprite; ProjectedTextGeometryView *arrow_sprite; } VsJutsuSelectorView;

typedef struct CommandMenuLayersView { unsigned char _unknown_00[0x48]; void *sprites[7]; } CommandMenuLayersView;

typedef struct EffectAuxVisual { unsigned char _unknown_00[0x60]; void *composition; void *primary; void *secondary; short countdown; short effect; short side; unsigned char _unknown_72[0xe]; } EffectAuxVisual;

typedef struct EffectAuxSelector { int effect; signed char selector; unsigned char _unknown_05[3]; } EffectAuxSelector;

typedef struct BattleResultsCloud { float x; float y; float speed; float width; float height; } BattleResultsCloud;

typedef struct BattleResultsSummaryView { unsigned char _unknown_0000[0x10]; short side; short state; unsigned short elapsed; unsigned char _unknown_0016[0xA]; BattleResultsCloud clouds[5]; unsigned char _unknown_0084[0x94]; void *footer_render_context; void *stamp_animation; unsigned char _unknown_0120[0x20]; void *details_sprite; void *prompt_sprite; unsigned char _unknown_0148[4]; void *shared_rank_sprite; unsigned char _unknown_0150[0xC]; unsigned char stamp_rank; unsigned char _unknown_015d[3]; int result_rank; } BattleResultsSummaryView;

typedef struct NinjaSongResultRow { struct NinjaSongArithmeticDescriptorView *descriptor; int value; int total; } NinjaSongResultRow;

typedef struct NinjaSongDetailsView { unsigned char _unknown_0000[4]; NinjaSongResultRow *rows; unsigned char _unknown_0008[8]; short side; short state; unsigned short elapsed; unsigned char _unknown_0016[0x2A]; void *font; unsigned char _unknown_0044[0x1C]; float scroll; float scroll_limit; } NinjaSongDetailsView;

typedef struct VictoryNameRectangle { short u; short v; short width; short height; float local_x; float local_y; float display_width; float display_height; } VictoryNameRectangle;

typedef struct VictoryPresentationOwnerView { unsigned char _unknown_00[0xc]; void *animation_players[3]; ProjectedTextGeometryView *name_sprite; ProjectedTextGeometryView *count_sprite; short state; short elapsed; short character_id; short win_count; unsigned char _unknown_28[8]; int resource_request; float name_displacement; float echo_scale[2]; float echo_opacity[2]; unsigned char echo_enabled[2]; unsigned char _unknown_4a[2]; } VictoryPresentationOwnerView;

typedef struct BattleVictoryNameView { unsigned char _unknown_0000[0x3c8]; VictoryNameRectangle first_name; VictoryNameRectangle second_name; } BattleVictoryNameView;

typedef struct LocalizedVictoryWidths { unsigned short first; unsigned short second; unsigned char _unknown_04[4]; } LocalizedVictoryWidths;

typedef struct UiTextDrawRecord { float x; float y; char *text; unsigned int indexed_color; } UiTextDrawRecord;

typedef struct UiPanel { int style; float x; float y; float width; float height; unsigned char _unknown_0014[0x4e]; unsigned char text_enabled; unsigned char _unknown_0063[5]; short text_inset_x; short text_inset_y; unsigned char _unknown_006c[0xc]; void *text_context; void *text_draw_object; } UiPanel;

typedef struct SaveDialogUi { unsigned char visible; unsigned char text_enabled; unsigned char choice_enabled; unsigned char slots_visible; unsigned char slots_enabled; unsigned char _unknown_0005[3]; int mode; int port; int selected_slot; int choice; float selected_x_offset; UiPanel *lower_panel; UiPanel *upper_panel; unsigned char _unknown_0024[0x10]; struct SaveDescriptorNumericView *slots[3]; unsigned char _unknown_0040[4]; char *text; } SaveDialogUi;

typedef struct VsConfirmationPromptView { unsigned char _unknown_00[4]; int participant_choices[2]; unsigned char _unknown_0c[8]; void *selection_sprite; void *footer_sprite; unsigned char _unknown_1c[0x1c]; int alternate_prompt_enabled; int practice_prompt_enabled; } VsConfirmationPromptView;

typedef struct CommandScrollIndicatorView { unsigned char _unknown_00[0xc]; unsigned char pulse_rising; unsigned char _unknown_0d[3]; float pulse_offset; short pulse_count; } CommandScrollIndicatorView;

typedef struct Mwo3LoadHeader { unsigned char _unknown_0000[0x14]; unsigned int bss_size; void **constructor_begin; void **constructor_end; } Mwo3LoadHeader;

typedef struct FontGlyphMetrics { unsigned char left_margin; unsigned char top_margin; unsigned char right_margin; unsigned char bottom_margin; } FontGlyphMetrics;

typedef struct SaveDescriptorNumericView { unsigned char occupied; unsigned char _unknown_0001[3]; int play_time; unsigned char _unknown_0008[4]; unsigned char day; unsigned char month; unsigned short year; } SaveDescriptorNumericView;

typedef struct FontGlyphDescriptor { unsigned char output_width; unsigned char output_height; unsigned char cell_width; unsigned char cell_height; unsigned char _unknown_04[0x14]; struct FontGlyphMetrics *metrics; } FontGlyphDescriptor;

typedef struct PracticeCompletionView { unsigned char _unknown_00[8]; ActionNameView *completed_move; unsigned char _unknown_0c[0x48]; void *render_context; unsigned char _unknown_58[8]; void *panel_sprite; void *ok_sprite; unsigned char _unknown_68[0x24]; short font_transform; unsigned char _unknown_8e[2]; float panel_opacity; float fade_progress; float ok_scale; int shake_count; } PracticeCompletionView;

typedef struct BattleCommandStripView { unsigned char _unknown_00[0x2f4]; char *title; unsigned char _unknown_2f8[8]; int anchor_x; int anchor_y; short animation_offset; short frame_width; unsigned char _unknown_30c[4]; unsigned char active; } BattleCommandStripView;

typedef struct PracticeSettingsTextView { unsigned char _unknown_00[0x3c]; int selection; unsigned char _unknown_40[4]; float row_offset; unsigned char _unknown_48[0x24]; int values[17]; } PracticeSettingsTextView;

typedef struct CharacterSelectFooterView { int state; int mode; unsigned char _unknown_0008[4]; int controller[2]; unsigned char _unknown_0014[0x464]; CharacterSelectorFooterView *selectors[2]; unsigned char _unknown_0480[0x14]; void *charsel_sprites; void *common_prompts; unsigned char _unknown_049c[0x14]; float footer_pulse_phase; } CharacterSelectFooterView;

typedef struct CollectionPlaqueView { int title_enabled; unsigned char _unknown_04[0xC]; float x; float y; unsigned char _unknown_18[8]; char *title; } CollectionPlaqueView;

typedef struct CollectionListLayoutView { unsigned char _unknown_00[0x14]; float box_width; float box_height; } CollectionListLayoutView;

typedef struct CollectionCharacterRemapRecord { int character_id; int localized_row; } CollectionCharacterRemapRecord;

typedef struct LocalizedCharacterNameRecord { char *primary_title; char *collection_title; } LocalizedCharacterNameRecord;

typedef struct BattleHudNameAnchorView { float draw_x; float draw_y; float scale; unsigned char side; } BattleHudNameAnchorView;

typedef struct BattleHudNameView { BattleHudNameAnchorView *parent; ProjectedTextGeometryView *sprite; } BattleHudNameView;

typedef struct BattlePromptRectangle { unsigned short u; unsigned short v; unsigned short width; unsigned short height; } BattlePromptRectangle;

typedef struct BattlePromptDisplayView { unsigned char _unknown_00[4]; void *context; unsigned char _unknown_08[0xc]; float opacity; float echo_opacity; float echo_scale; unsigned char _unknown_20[8]; short side; unsigned char _unknown_2a[5]; unsigned char label; unsigned char commands[1]; unsigned char _unknown_31[0x54f]; } BattlePromptDisplayView;

typedef struct CharacterSelectorFooterView { int state; } CharacterSelectorFooterView;

typedef struct MoveChartRow {
    char *name;
    unsigned char condition_index;
    unsigned char category_index;
    unsigned char _unknown_06[2];
    int tokens[10];
    int last_token_index;
} MoveChartRow;

typedef struct MoveChartView {
    unsigned char _unknown_00[0x34];
    short row_count;
    short scroll;
    short visible_rows;
    short scroll_direction;
    short row_y;
    short row_offset;
    MoveChartRow rows[1]; /* partial view; no row-capacity claim */
} MoveChartView;

typedef struct Nun5StageRecord { int stage_id; int preview_index; } Nun5StageRecord;

typedef struct StageSelectView { int state; unsigned char _unknown_0004[12]; int choice_count; int choices[24]; int choice_index; float carousel_displacement; unsigned char _unknown_007c[24]; float random_phase; unsigned char _unknown_0098[16]; void *settings; void *mapsel_container; void *scene_draw_list; void *sprite_draw_list; void *legend_sprite; void *name_sprite; void *prompt_sprite; void *digit_sprite; void *camera_animation; void *selection_animation; void *ring_animation1; void *ring_animation2; unsigned char _unknown_00d8[4]; void *tv_animation; void *titlebox; void *carousel; void *owned_objects[24]; } StageSelectView;
