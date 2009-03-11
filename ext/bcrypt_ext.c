#include "ruby.h"
#include "blf.h"

char   *bcrypt_gensalt(u_int8_t, u_int8_t *);
char   *bcrypt(const char *, const char *);

VALUE mBCrypt;
VALUE cBCryptEngine;

/* Define RSTRING_PTR for Ruby 1.8.5, ruby-core's idea of a point release is
   insane. */
#ifndef RSTRING_PTR
#  define    RSTRING_PTR(s)  (RSTRING(s)->ptr)
#endif

/* Given a logarithmic cost parameter, generates a salt for use with +bc_crypt+.
 */
static VALUE bc_salt(VALUE self, VALUE cost, VALUE seed) {
	return rb_str_new2((char *)bcrypt_gensalt(NUM2INT(cost), (u_int8_t *)RSTRING_PTR(seed)));
}

/* Given a secret and a salt, generates a salted hash (which you can then store safely).
 */
static VALUE bc_crypt(VALUE self, VALUE key, VALUE salt) {
	const char * safeguarded = RSTRING_PTR(key) ? RSTRING_PTR(key) : "";
	return rb_str_new2((char *)bcrypt(safeguarded, (char *)RSTRING_PTR(salt)));
}

/* Create the BCrypt and BCrypt::Internals modules, and populate them with methods. */
void Init_bcrypt_ext(){
	mBCrypt = rb_define_module("BCrypt");
	cBCryptEngine = rb_define_class_under(mBCrypt, "Engine", rb_cObject);
	
	rb_define_singleton_method(cBCryptEngine, "__bc_salt", bc_salt, 2);
	rb_define_singleton_method(cBCryptEngine, "__bc_crypt", bc_crypt, 2);
}
