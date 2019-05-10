#ifndef __RPCP_TEST__
#define __RPCP_TEST__

$if(model.IsTest)$

#include <stdint.h>
#include <stdbool.h>

typedef struct {
  int count_tested;  /* the number of tested pins */
  int count_success; /* the number of successfully tested pins */
  int count_failed;  /* the number of failed tests */
  int count_failed_low; /* the number of tests that failed because the pin was not low */
  int count_failed_high; /* the number of tests that failed because the input was not high */
  int index_failed; /* the index of the first item that failed */
  bool success;   /* true if the test was successful */
} testresult_t;

void rpcp_test_init(void); /* initialize the test modules */
bool rpcp_test_run(testresult_t *result); /* run the tests */

$endif$

#endif