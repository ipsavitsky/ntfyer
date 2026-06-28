#ifndef NTFYER_C_H
#define NTFYER_C_H

/* Process glibc headers that gate on __GNUC__ >= 7 (for the _FloatN keyword
 * types) while __GNUC__ still has its real, high value. Their include guards
 * mean they will not be reprocessed below. */
#include <stdio.h>
#include <time.h>
#include <sys/types.h>

/* Undefine __GNUC__ entirely so GLib's gmacros.h takes its "not GNU C" branches,
 * which define the deprecation macros (G_GNUC_BEGIN_IGNORE_DEPRECATIONS etc.)
 * and the autoptr cleanup macros (G_DEFINE_AUTOPTR_CLEANUP_FUNC etc.) as empty.
 * The former avoids the _Pragma(...) aro cannot parse; the latter avoids
 * translate-c mis-translating the GString cleanup into invalid Zig. */
#undef __GNUC__
#undef __GNUC_MINOR__

#include <libnotify/notify.h>

#endif
