/*
(c) 2019-2020 by kitten_nb_five

licence: AGPL v3 or later

THIS PROGRAM COMES WITHOUT ANY WARRANTY!
*/

#ifndef __MY_ERR_H__
#define __MY_ERR_H__

#include <err.h>

//append to_string(errno)
#define ERR(r, fmt, ...) err(r, "%s(): %u: "fmt, __FUNCTION__, __LINE__, ##__VA_ARGS__)

//don't append anything
#define ERRX(r, fmt, ...) errx(r, "%s(): %u: "fmt, __FUNCTION__, __LINE__, ##__VA_ARGS__)

#endif
