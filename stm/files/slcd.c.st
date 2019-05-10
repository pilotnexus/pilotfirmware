#include <string.h>
#include "stm32_conf.h"
#include "slcd.h"
#include "delay.h"

#define DISPLAY_MAX_WIDTH  400
#define DISPLAY_MAX_HEIGHT 240
#define DISPLAY_BUFFERSIZE ((DISPLAY_MAX_WIDTH * DISPLAY_MAX_HEIGHT) / 8)

#define DISPLAY_DEFAULT_WIDTH 128
#define DISPLAY_DEFAULT_HEIGHT 128

#define RESOLUTION_GET_BYTES(r) (r.width * r.height / 8)

typedef enum
{
  slcd_mode_flags_update = 1 << 7,
  slcd_mode_flags_clear  = 1 << 5
} slcd_mode_flags_t;

typedef struct
{
  uint8_t data[DISPLAY_BUFFERSIZE];
  int index;
  slcd_resolution_t resolution;
} slcd_display_buffer_t;

$model.SLCDs:{slcd|

/* the display buffer */
static slcd_display_buffer_t m_$slcd.Name$_display_buffer;

void rpcp_$slcd.Name$_get_resolution(slcd_resolution_t *resolution)
{
  if (resolution != NULL)
  {
    resolution->width = m_$slcd.Name$_display_buffer.resolution.width;
    resolution->height = m_$slcd.Name$_display_buffer.resolution.height;
  \}
\}

void rpcp_$slcd.Name$_set_resolution(const slcd_resolution_t *resolution)
{
  if (resolution != NULL)
  {
    m_$slcd.Name$_display_buffer.resolution.width = resolution->width;
    m_$slcd.Name$_display_buffer.resolution.height = resolution->height;
  \}
\}

static uint8_t rpcp_$slcd.Name$_get_gateline_adress(int line)
{
  /* reverse bit order */
  uint8_t b = (uint8_t)line;
  b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
  b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
  b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
  return b;
\}

static void rpcp_$slcd.Name$_send_buffer()
{
  int i, j;

  /* updating the display using Data Update Mode for Multiple Lines */

  /* pull chip select high for the remainder of the communication */
  if (rpcp_spi_set_cs(spi_id_$slcd.SPI.Id$, chip_select_enable))
  {
    /* send mode selection */
    rpcp_spi_send(spi_id_$slcd.SPI.Id$, (uint16_t)slcd_mode_flags_update);

    /* send the content of the display buffer per line */
    for (i = 0; i < m_$slcd.Name$_display_buffer.resolution.height; i++)
    {
      /* send the gate line address */
      rpcp_spi_send(spi_id_$slcd.SPI.Id$, rpcp_$slcd.Name$_get_gateline_adress(i + 1));

      /* send a complete line */
      for (j = 0; j < m_$slcd.Name$_display_buffer.resolution.width / 8; j++)
        rpcp_spi_send(spi_id_$slcd.SPI.Id$, m_$slcd.Name$_display_buffer.data[j + (i * m_$slcd.Name$_display_buffer.resolution.width / 8)]);

      /* send 8-bits of dummy data */
      rpcp_spi_send(spi_id_$slcd.SPI.Id$, 0x00);

    \}

    /* send 8-bits of dummy data */
    rpcp_spi_send(spi_id_$slcd.SPI.Id$, 0x00);

    rpcp_delay_us(2);

    /* pull chip select low again */
    rpcp_spi_set_cs(spi_id_$slcd.SPI.Id$, chip_select_disable);
  \}

  /* toggle EXTCOMIN */
  GPIO_WriteBit($slcd.EXTCOMIN.GPIO$, $slcd.EXTCOMIN.Pin$,
    GPIO_ReadOutputDataBit($slcd.EXTCOMIN.GPIO$, $slcd.EXTCOMIN.Pin$) == Bit_SET ? Bit_RESET : Bit_SET
  );
\}

/* prepare updating the display buffer with data */
void rpcp_$slcd.Name$_update_buffer_start()
{
  m_$slcd.Name$_display_buffer.index = 0;
\}

/* update the display buffer with the data */
void rpcp_$slcd.Name$_update_buffer_data(uint8_t data)
{
  /* get the bytes needed to complete a frame at this resolution */
  int resolution_bytes = RESOLUTION_GET_BYTES(m_$slcd.Name$_display_buffer.resolution);

  /* if there is still room in the buffer */
  if (m_$slcd.Name$_display_buffer.index < DISPLAY_BUFFERSIZE &&
      m_$slcd.Name$_display_buffer.index < resolution_bytes)
  {
    /* add the data to the display buffer */
    m_$slcd.Name$_display_buffer.data[m_$slcd.Name$_display_buffer.index++] = data;

    /* is this the last byte that is required to render to the resolution? */
    if (m_$slcd.Name$_display_buffer.index == resolution_bytes)
      rpcp_$slcd.Name$_send_buffer(); /* then render to the display */
  \}
\}

static void rpcp_$slcd.Name$_init_gpios()
{
  /* enable gpio clock */
  RCC_$slcd.EXTCOMIN.Periph$PeriphClockCmd(RCC_$slcd.EXTCOMIN.Periph$Periph_$slcd.EXTCOMIN.GPIO$, ENABLE);

  /* configure EXTCOMIN as output */
  GPIO_InitTypeDef gpio;
  gpio.GPIO_Speed = GPIO_Speed_50MHz;
  gpio.GPIO_Pin = $slcd.EXTCOMIN.Pin$;
  gpio.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init($slcd.EXTCOMIN.GPIO$, &gpio);
\}

/* initialize the sharp display driver */
void rpcp_$slcd.Name$_init()
{
  /* initialize the gpios */
  rpcp_$slcd.Name$_init_gpios();

  /* set some default values for line length & count */
  m_$slcd.Name$_display_buffer.resolution.width = DISPLAY_DEFAULT_WIDTH;
  m_$slcd.Name$_display_buffer.resolution.height = DISPLAY_DEFAULT_HEIGHT;
\}

}; separator="\n"$