#ifndef LED_H
#define LED_H

#include "stm32f4xx_hal.h"

void LED_Init(void);
void LED_On(void);
void LED_Off(void);
void LED_Toggle(void);

#endif /* LED_H */
