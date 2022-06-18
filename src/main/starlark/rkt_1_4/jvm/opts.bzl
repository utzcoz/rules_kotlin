load("@dev_io_bazel_rules_kotlin//src/main/starlark/core/options:derive.bzl", "derive")

_JOPTS = {
    "warn": struct(
        args = dict(
            default = "report",
            doc = "Control warning behaviour.",
            values = ["off", "report", "error"],
        ),
        type = attr.string,
        value_to_flag = {
            "off": ["-nowarn"],
            "error": ["-Werror"],
            "report": None,
        },
    ),
    "x_ep_disable_all_checks": struct(
        args = dict(
            default = False,
            doc = "See javac -XepDisableAllChecks documentation",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-XepDisableAllChecks"],
        },
    ),
    "x_lint": struct(
        args = dict(
            default = [],
            doc = "See javac -Xlint: documentation",
        ),
        type = attr.string_list,
        value_to_flag = {
            derive.info: derive.repeated_values_for("-Xlint:"),
        },
    ),
    "xd_suppress_notes": struct(
        args = dict(
            default = False,
            doc = "See javac -XDsuppressNotes documentation",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-XDsuppressNotes"],
        },
    ),
}

def _javac_options_impl(ctx):
    return struct(
        providers = [
            JavacOptions(**{n: getattr(ctx.attr, n, None) for n in _JOPTS}),
        ],
    )

JavacOptions = provider(
    fields = {
        name: o.args["doc"]
        for name, o in _JOPTS.items()
    },
)

kt_javac_options = rule(
    implementation = _javac_options_impl,
    doc = "Define java compiler options for `kt_jvm_*` rules with java sources.",
    provides = [JavacOptions],
    attrs = {n: o.type(**o.args) for n, o in _JOPTS.items()},
)

def javac_options_to_flags(javac_options):
    """Translate JavacOptions to worker flags

    Args:
        javac_options of type JavacOptions or None
    Returns:
        list of flags to add to the command line.
    """
    if not javac_options:
        return ""

    flags = []
    for n, o in _JOPTS.items():
        value = getattr(javac_options, n, None)
        if derive.info in o.value_to_flag:
            info = o.value_to_flag[derive.info]
            flags.extend(info.derive(info.ctx, value))
        elif o.value_to_flag.get(value, None):
            flags.extend(o.value_to_flag[value])

    return flags
