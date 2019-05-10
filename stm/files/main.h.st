#ifndef MAIN_H
#define MAIN_H

void __attribute__((weak)) init_plugins();
void __attribute__((weak)) init_custom();
void __attribute__((weak)) before_loop_plugins();
void __attribute__((weak)) before_loop_custom();
void __attribute__((weak)) after_loop_plugins();
void __attribute__((weak)) after_loop_custom();

#endif