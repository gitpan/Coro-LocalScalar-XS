#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "CoroAPI.h"


typedef struct {
	HV* values_container;
	SV* scalar;
} local_scalar;


static HV* data_hash;


static HV* get_local_storage (void){
	
	SV** local_storage = hv_fetch( data_hash , (char *) CORO_CURRENT , sizeof(HV*), 0);
	
	if(!local_storage){
		HV* new_storage = newHV();
	
		hv_store(data_hash, (char *) CORO_CURRENT , sizeof(HV*) , newRV_noinc((SV *) new_storage) , 0);
		
		dSP;
		PUSHMARK(SP);
		call_pv("Coro::LocalScalar::XS::_set_ondestroy_cb", G_DISCARD|G_NOARGS);
		
		
		return new_storage;
	}
	
	return (HV*) SvRV( *local_storage );
}



static int localized_read (pTHX_ SV* sv, MAGIC* mg) {
	
	SV** local_value = hv_fetch( get_local_storage() , (char *) sv, sizeof(SV*), 0);
	
	sv_setsv(sv, 
		local_value ? *local_value :  &PL_sv_undef
	);

	return 0;
}

static int localized_write (pTHX_ SV* sv, MAGIC* mg) {

	hv_store( get_local_storage() ,  (char *) sv, sizeof(SV*) , newSVsv(sv) , 0);
	
	sv_setsv(sv, &PL_sv_undef );
	
	return 0;
}


static MGVTBL vtbl = {
	localized_read,
	localized_write,
};


MODULE = Coro::LocalScalar::XS	PACKAGE = Coro::LocalScalar::XS	

PROTOTYPES: DISABLE

BOOT: 
	I_CORO_API ("Coro::LocalScalar::XS");
	data_hash = newHV();



void
_init (sv)
	SV* sv
	CODE:
		sv_magicext (sv, 0, PERL_MAGIC_ext, &vtbl, (const char*) 0 , 0);
		
HV*
_get_data_hash()
	CODE:
		RETVAL = (HV*) SvREFCNT_inc((SV*)data_hash);
	OUTPUT:
		RETVAL
	


	
void
cleanup(coro)
	SV* coro
	CODE:
		HV* local_storage = (HV*) SvRV(  *(hv_fetch( data_hash , (char *) SvRV(coro) , sizeof(HV*), 0)) );
		
		int keys = hv_iterinit( local_storage);
		SV* sv;
		int i;
		int len;
		for(i = 0; i < keys; i++){
			HE* entry = hv_iternext( local_storage );
			
			sv_setsv( (SV*) hv_iterkey(entry, &len) , &PL_sv_undef );
		}
		
		hv_delete(data_hash, (char *) SvRV(coro), sizeof(HV*), G_DISCARD);
		

