#define INSTRUMENT_MIN_OCTAVE 1
#define INSTRUMENT_MAX_OCTAVE 9
#define INSTRUMENT_MIN_KEY 0
#define INSTRUMENT_MAX_KEY 127

/// Max number of playing notes per instrument.
#define CHANNELS_PER_INSTRUMENT 128

/// Minimum length a note should ever go for
#define INSTRUMENT_MIN_TOTAL_SUSTAIN 0.1
/// Maximum length a note should ever go for
#define INSTRUMENT_MAX_TOTAL_SUSTAIN (5 SECONDS)

/// These are per decisecond.
#define INSTRUMENT_EXP_FALLOFF_MIN 1.025 //100/(1.025^50) calculated for [INSTRUMENT_MIN_SUSTAIN_DROPOFF] to be 30.
#define INSTRUMENT_EXP_FALLOFF_MAX 10

/// Minimum volume for when the sound is considered dead.
#define INSTRUMENT_MIN_SUSTAIN_DROPOFF 0

/// Internal gain applied after the user-facing 0-100 volume slider.
#define INSTRUMENT_OUTPUT_GAIN 2
/// OGG tracks are mastered very differently, so file playback gets extra headroom.
#define INSTRUMENT_FILE_OUTPUT_GAIN 3
/// Instrument sounds should keep full volume for a few tiles before falling off.
#define INSTRUMENT_FALLOFF_DISTANCE 4
/// Softer than generic one-shot sound falloff; music should carry around the source.
#define INSTRUMENT_FALLOFF_EXPONENT 3

#define SUSTAIN_LINEAR "Linear"
#define SUSTAIN_EXPONENTIAL "Exponential"

// /datum/instrument instrument_flags
#define INSTRUMENT_LEGACY (1<<0) //Legacy instrument. Implies INSTRUMENT_DO_NOT_AUTOSAMPLE
#define INSTRUMENT_DO_NOT_AUTOSAMPLE (1<<1) //Do not automatically sample
