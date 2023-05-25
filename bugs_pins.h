#if defined(ARDUINO_ARCH_ESP8266)
const int mcpOffset = 32;
#elif defined(ARDUINO_ARCH_ESP32)
const int mcpOffset = 64;
#define LED_BUILTIN 2
#define TX0 1
#define D2  2
#define RX0 3
#define D4  4
#define D5  5
#define D12 12
#define D13 13
#define D14 14
#define D15 15
#define D16 16
#define D17 17
#define D18 18
#define D19 19
#define D21 21
#define D22 22
#define D23 23
#define D25 25
#define D26 26
#define D27 27
#define D32 32
#define D33 33
#define D34 34
#define D35 35
#define D36 36
#define D39 39
#endif

#define GPA0 mcpOffset + 0
#define GPA1 mcpOffset + 1
#define GPA2 mcpOffset + 2
#define GPA3 mcpOffset + 3
#define GPA4 mcpOffset + 4
#define GPA5 mcpOffset + 5
#define GPA6 mcpOffset + 6
#define GPA7 mcpOffset + 7
#define GPB0 mcpOffset + 8
#define GPB1 mcpOffset + 9
#define GPB2 mcpOffset + 10
#define GPB3 mcpOffset + 11
#define GPB4 mcpOffset + 12
#define GPB5 mcpOffset + 13
#define GPB6 mcpOffset + 14
#define GPB7 mcpOffset + 15

#define PA0 GPA0
#define PA1 GPA1
#define PA2 GPA2
#define PA3 GPA3
#define PA4 GPA4
#define PA5 GPA5
#define PA6 GPA6
#define PA7 GPA7
#define PB0 GPB0
#define PB1 GPB1
#define PB2 GPB2
#define PB3 GPB3
#define PB4 GPB4
#define PB5 GPB5
#define PB6 GPB6
#define PB7 GPB7

#define INPUT_DS18B20 0x41
#define INPUT_TA12    0x42
#define INPUT_LUX     0x43
#define INPUT_DHT11   0x44
#define INPUT_DHT22   0x45

#define LUX_MIN_VALUE 0
#define LUX_MAX_VALUE 4095

void PIN_assign(int PIN, char *name, float state, int mode);
bool PIN_callback(char topic[64], char buffer[64]);
void PIN_check();
void PIN_fill();
void PIN_init(bool mcpEnable, void (*userDefinedCallback)(const int, const float, const bool));
void PIN_set(int PIN, float state);
float PIN_state(int PIN);
void PIN_subscribe();
void PIN_toggle(int PIN);
