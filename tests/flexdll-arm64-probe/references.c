/* Object-format probe only: deliberately refers to unresolved host symbols. */
#ifdef USE_DLLIMPORT
#define IMPORT __declspec(dllimport)
#else
#define IMPORT
#endif

IMPORT extern int host_value;
IMPORT int host_function(int);

int *get_host_value_address(void) { return &host_value; }
int read_host_value(void) { return host_value; }
int call_host_function(int x) { return host_function(x) + host_value; }

#ifndef USE_DLLIMPORT
int *host_data_pointer = &host_value;
int (*host_function_pointer)(int) = &host_function;
#endif
