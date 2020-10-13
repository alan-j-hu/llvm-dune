#!/bin/sh -ex

llvm_config=$1
default_mode=
support_static_mode=false
support_dynamic_mode=false

if "$llvm_config" --link-static --libs; then
    default_mode=static
    support_static_mode=true
fi

if "$llvm_config" --link-shared --libs; then
    default_mode=dynamic
    support_dynamic_mode=true
fi

rm -rf build
cp -r llvm-project/llvm/bindings/ocaml build

create_dune_file() {
    findlibname=$1
    dirname=$2
    modname=$3
    cfile=$4
    libname=$5
    depends=$6

    basedir=build/$dirname

    test ! -d $basedir/common && mkdir $basedir/common
    cp $basedir/$modname.mli $basedir/common

    echo "
(library
 (name $libname)
 (public_name $findlibname)
 (wrapped false)
 (virtual_modules $modname)
 (libraries $depends)
 (default_implementation $findlibname.$default_mode))
" > $basedir/common/dune

    if $support_dynamic_mode; then
        test ! -d $basedir/dynamic && mkdir $basedir/dynamic
        cp $basedir/$modname.ml $basedir/dynamic
        cp $basedir/$cfile.c $basedir/dynamic

        echo "
(library
 (name ${libname}_dynamic)
 (public_name $findlibname.dynamic)
 (implements $libname)
 (foreign_stubs
  (language c)
  (names ${cfile})
  (flags (-I/usr/lib/llvm-10/include  -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS))))
" >> $basedir/dynamic/dune
    fi

    if $support_static_mode; then
        test ! -d $basedir/static && mkdir $basedir/static
        cp $basedir/$modname.ml $basedir/static
        cp $basedir/$cfile.c $basedir/static

        echo "
(library
 (name ${libname}_static)
 (public_name $findlibname.static)
 (implements $libname)
 (foreign_stubs
  (language c)
  (names ${cfile})
  (flags (-I/usr/lib/llvm-10/include  -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS))))
" >> $basedir/static/dune
    fi

    rm $basedir/$modname.ml
}

create_dune_file llvm llvm llvm llvm_ocaml llvm ""
create_dune_file llvm.analysis analysis llvm_analysis analysis_ocaml analysis "llvm"
create_dune_file llvm.bitreader bitreader llvm_bitreader bitreader_ocaml bitreader "llvm"
create_dune_file llvm.bitwriter bitwriter llvm_bitwriter bitwriter_ocaml bitwriter "llvm unix"
create_dune_file llvm.executionengine executionengine llvm_executionengine executionengine_ocaml executionengine "llvm llvm.target ctypes.foreign"
create_dune_file llvm.ipo transforms/ipo llvm_ipo ipo_ocaml ipo "llvm"
create_dune_file llvm.irreader irreader llvm_irreader irreader_ocaml irreader "llvm"
create_dune_file llvm.scalar_opts transforms/scalar_opts llvm_scalar_opts scalar_opts_ocaml scalar_opts "llvm"
create_dune_file llvm.transform_utils transforms/utils llvm_transform_utils transform_utils_ocaml transform_utils "llvm"
create_dune_file llvm.vectorize transforms/vectorize llvm_vectorize vectorize_ocaml vectorize "llvm"
create_dune_file llvm.passmgr_builder transforms/passmgr_builder llvm_passmgr_builder passmgr_builder_ocaml passmgr_builder "llvm"
create_dune_file llvm.target target llvm_target target_ocaml target "llvm"
create_dune_file llvm.linker linker llvm_linker linker_ocaml linker "llvm"
create_dune_file llvm.all_backends all_backends llvm_all_backends all_backends_ocaml all_backends "llvm"

# TODO: do /backends
