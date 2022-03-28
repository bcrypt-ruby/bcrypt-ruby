#include <ruby.h>
#include <ow-crypt.h>

static VALUE mBCrypt;
static VALUE cBCryptEngine;

/* Given a logarithmic cost parameter, generates a salt for use with +bc_crypt+.
*/
static VALUE bc_salt(VALUE self, VALUE prefix, VALUE count, VALUE input) {
    char * salt;
    VALUE str_salt;

    salt = crypt_gensalt_ra(
	    StringValuePtr(prefix),
	    NUM2ULONG(count),
	    NIL_P(input) ? NULL : StringValuePtr(input),
	    NIL_P(input) ? 0 : RSTRING_LEN(input));

    if(!salt) return Qnil;

    str_salt = rb_str_new2(salt);
    free(salt);

    return str_salt;
}

static char *string_from_value(VALUE value) {
    char *string = NULL;
    long length;

    if (NIL_P(value)) return NULL;

    length = RSTRING_LEN(value);
    string = (char *)malloc(length + 1);

    if (string == NULL) return NULL;

    memset(string, 0, length + 1);
    strncpy(string, RSTRING_PTR(value), length);

    return string;
}

/* Wraps crypt_ra to ensure strings passed are correctly terminated
 */
static char *crypt_ra_wrapper(VALUE key, VALUE setting, void **data, int *size) {
    char *value;
    char *key_string, *setting_string = NULL;

    key_string = string_from_value(key);
    setting_string = string_from_value(setting);

    value = crypt_ra(
	    key_string,
	    setting_string,
	    data,
	    size);


    free(key_string);
    free(setting_string);

    return value;
}

/* Given a secret and a salt, generates a salted hash (which you can then store safely).
*/
static VALUE bc_crypt(VALUE self, VALUE key, VALUE setting) {
    char * value;
    void * data;
    int size;
    VALUE out;

    data = NULL;
    size = 0xDEADBEEF;

    if(NIL_P(key) || NIL_P(setting)) return Qnil;

    value = crypt_ra_wrapper(
	    key,
	    setting,
	    &data,
	    &size);

    if(!value || !data) return Qnil;

    out = rb_str_new2(value);

    xfree(data);

    return out;
}

/* Create the BCrypt and BCrypt::Engine modules, and populate them with methods. */
void Init_bcrypt_ext(){
    mBCrypt = rb_define_module("BCrypt");
    cBCryptEngine = rb_define_class_under(mBCrypt, "Engine", rb_cObject);

    rb_define_singleton_method(cBCryptEngine, "__bc_salt", bc_salt, 3);
    rb_define_singleton_method(cBCryptEngine, "__bc_crypt", bc_crypt, 2);
}

/* vim: set noet sws=4 sw=4: */
