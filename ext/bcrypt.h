#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include "blf.h"

/* This implementation is adaptable to current computing power.
 * You can have up to 2^31 rounds which should be enough for some
 * time to come.
 */

#define BCRYPT_VERSION '2'
#define BCRYPT_MAXSALT 16	/* Precomputation is just so nice */
#define BCRYPT_BLOCKS 6		/* Ciphertext blocks */
#define BCRYPT_MINROUNDS 16	/* we have log2(rounds) in salt */

char   *bcrypt_gensalt(u_int8_t, u_int8_t *);

static void encode_salt(char *, u_int8_t *, u_int16_t, u_int8_t);
static void encode_base64(u_int8_t *, u_int8_t *, u_int16_t);
static void decode_base64(u_int8_t *, u_int16_t, u_int8_t *);

static char    encrypted[_PASSWORD_LEN];
static char    gsalt[7 + (BCRYPT_MAXSALT * 4 + 2) / 3 + 1];
static char    error[] = ":";

const static u_int8_t Base64Code[] =
"./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

const static u_int8_t index_64[128] = {
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 0, 1, 54, 55,
	56, 57, 58, 59, 60, 61, 62, 63, 255, 255,
	255, 255, 255, 255, 255, 2, 3, 4, 5, 6,
	7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
	17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
	255, 255, 255, 255, 255, 255, 28, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
	51, 52, 53, 255, 255, 255, 255, 255
};
#define CHAR64(c)  ( (c) > 127 ? 255 : index_64[(c)])