-- Shared time bases and client protocol values. Durations are in seconds.
return {
    LOGIC_TICKS_PER_SECOND = 50,
    SERVER_TICK_SECONDS = 0.6,
    SECONDS_PER_MINUTE = 60,
    SECONDS_PER_HOUR = 3600,
    CHECK_RETRY_SECONDS = 5,
    PRESET_CHAT_WINDOW_SECONDS = 5,
    BANK_CLOSE_WINDOW_SECONDS = 5,
    GAME_STATE = { PLAYING = 30, LOADING = 40 },
    KEY_ESCAPE = 13,
    MODIFIER = { SHIFT = 1, CONTROL = 2, ALT = 4 },
}
