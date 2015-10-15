# cf-example-ruby-sinatra

Test application for cloudfoundry. It implements several useful endpoints
to test different failure and performance scenarios.

## Endpoints

### /

Return a 'Hello world' home page

### /environment

Prints out system environment variables.

### /sleep/:milliseconds

Sleep for x milliseconds before returning a response

### /mem/alloc/:size_mb/?:leak?/?:once?'

Allocates `size_mb` in MBs in memory before return a response.

Options:

 * `leak == 1`, optional, keep the memory allocated in application
    scope after returning a response (GC won't delete it)
 * `once == 1`, optional, allocate only once.

Example: `/mem/alloc/100/1/1`

### /mem/status

Print process memory and system free memory.

### /mem/touch

Forces read all the allocated memory, making the system to page in if required.

### /mem/free

Free the allocated memory.


