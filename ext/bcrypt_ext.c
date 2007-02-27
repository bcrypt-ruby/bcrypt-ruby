#include "ruby.h"

char   *bcrypt_gensalt(u_int8_t, u_int8_t *);
char   *bcrypt(const char *, const char *);

VALUE mBCrypt;
VALUE mBCryptInternals;

/* Given a logarithmic cost parameter, generates a salt for use with +bc_crypt+.
 */
static VALUE bc_salt(VALUE self, VALUE cost, VALUE seed) {
	return rb_str_new2((char *)bcrypt_gensalt(NUM2INT(cost), (u_int8_t *)RSTRING(seed)->ptr));
}

/* Given a secret and a salt, generates a salted hash (which you can then store safely).
 */
static VALUE bc_crypt(VALUE self, VALUE key, VALUE salt) {
	return rb_str_new2((char *)bcrypt(RSTRING(key)->ptr, (char *)RSTRING(salt)->ptr));
}

/* Create the BCrypt and BCrypt::Internals modules, and populate them with methods. */
void Init_bcrypt_ext(){
	mBCrypt = rb_define_module("BCrypt");
	mBCryptInternals = rb_define_module_under(mBCrypt, "Internals");
	
	rb_define_method(mBCryptInternals, "__bc_salt", bc_salt, 2);
	rb_define_method(mBCryptInternals, "__bc_crypt", bc_crypt, 2);
}
