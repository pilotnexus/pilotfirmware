#include "ai8.h"
$if(model.PLC)$
#include "iec_types_all.h"
$endif$

$model.IA8s:{ai8|

/* Start Single D2 D1 D0
1         1  0  0  0
d2 d1 d0 channel
0  0  0       0
0  0  1       1
0  1  0       2
0  1  1       3
1  0  0       4
1  0  1       5
1  1  0       6
1  1  1       7
*/

int pilot_$ai8.Name$_init()
{
  return 0;
\}

int pilot_$ai8.Name$_check()
{
  return 0;
\}

void pilot_$ai8.Name$_get_value(int input_index, uint16_t* value)
{
  uint8_t b1, b2;

  /* pull chip select low for the remainder of the communication */
  if (pilot_spi_set_cs(spi_id_$ai8.SPI.Id$, chip_select_enable))
  {
    /* first send the start bit & single bit, we don't care about the return value */
    pilot_spi_dataexchange(spi_id_$ai8.SPI.Id$, 0x06 | (input_index >> 2));

    /* then send the requested channel, the returned byte holds the first part of the value */
    b1 = pilot_spi_dataexchange(spi_id_$ai8.SPI.Id$, input_index << 6);

    /* the returned byte holds the second part of the value */
    b2 = pilot_spi_dataexchange(spi_id_$ai8.SPI.Id$, 0);

    /* set the requested value */
    *value = ((b1 << 8) | b2) & 0xFFF;

    /* pull chip select high again */
    pilot_spi_set_cs(spi_id_$ai8.SPI.Id$, chip_select_disable);
  \}
\}

$if(model.PLC)$
void pilot_$ai8.Name$_get_values(int input_index, int count, uint16_t* value, int minDelta)
{
  uint8_t b1, b2, i;
  uint16_t val;

  /* pull chip select low for the remainder of the communication */
  if (pilot_spi_set_cs(spi_id_$ai8.SPI.Id$, chip_select_enable))
  {
    for(i=input_index;i<(input_index+count);i++)
    {
      /* first send the start bit & single bit, we don't care about the return value */
      pilot_spi_dataexchange(spi_id_$ai8.SPI.Id$, 0x06 | (i >> 2));

      /* then send the requested channel, the returned byte holds the first part of the value */
      val = pilot_spi_dataexchange(spi_id_$ai8.SPI.Id$, i << 6) << 8;

      /* the returned byte holds the second part of the value */
      val |= pilot_spi_dataexchange(spi_id_$ai8.SPI.Id$, 0);

      if ((val & 0x1000) == 0) //else error
      {
        val &= 0xFFF;

        if (plc_$ai8.Name$_var_flags[i] != 0)
          if ( (val >= (*value + minDelta)) || (val <= (*value - minDelta)) )
            *plc_$ai8.Name$_var_flags[i] |= __IEC_DIRTY_FLAG;

        /* set the requested value */
        *value = val;
      \}
      value += sizeof(uint16_t);
    \}

    /* pull chip select high again */
    pilot_spi_set_cs(spi_id_$ai8.SPI.Id$, chip_select_disable);
  \}
\}
$endif$
};separator="\n"$