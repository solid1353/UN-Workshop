typedef struct HsynIndexSection { unsigned int magic; unsigned int section_tag; unsigned int unknown_08; unsigned int maximum_index; } HsynIndexSection;

typedef struct HsynProgramRecord { unsigned int split_offset; unsigned char split_count; unsigned char unknown_05[31]; } HsynProgramRecord;

typedef struct HsynProgramSplit { unsigned short set_index; unsigned char key_minimum; unsigned char unknown_03; unsigned char key_maximum; unsigned char unknown_05[15]; } HsynProgramSplit;

typedef struct HsynSetRecordPrefix { unsigned char unknown_00; unsigned char velocity_minimum; unsigned char velocity_maximum; unsigned char sample_count; } HsynSetRecordPrefix;

typedef struct HsynSampleRecord { unsigned short vag_index; unsigned char velocity_minimum; unsigned char unknown_03; unsigned char velocity_maximum; unsigned char unknown_05[9]; unsigned char exclusive_group; unsigned char priority; unsigned char unknown_10[25]; unsigned char core_and_mix_flags; } HsynSampleRecord;

typedef struct HsynVagRecord { unsigned int sample_offset; unsigned short sample_rate; unsigned char flags; unsigned char unknown_07; } HsynVagRecord;

typedef struct HsynBankBinding { unsigned char *head; HsynIndexSection *programs; HsynIndexSection *sets; HsynIndexSection *samples; HsynIndexSection *vags; unsigned char *setb; unsigned int spu_base; } HsynBankBinding;

typedef struct HsynChannel { unsigned char unknown_00[24]; HsynProgramRecord *program; unsigned int unknown_1c; HsynBankBinding *bank; unsigned char unknown_24[6]; unsigned char bank_index; unsigned char unknown_2b[13]; } HsynChannel;
