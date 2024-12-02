typedef struct __attribute__((__packed__)) {
  uint8_t tag;
  uint8_t length;
  uint8_t value[0];
} YKFOpenPGPTLV;

