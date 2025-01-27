from zapv2 import ZAPv2

global_target = ""


def zap_started(zap: ZAPv2, target):
    global global_target
    print("myhook.py: The target is:", target)
    global_target = target

    # note-update complete 302 handler
    zap.replacer.add_rule(
        description="Remove 'complete=on' from POST data",
        enabled=True,
        matchtype="REQ_BODY_STR",
        matchregex=False,
        matchstring="&complete=on",
        replacement="",
    )

    # Disable User Agent Fuzzer
    zap.ascan.disable_scanners("10104")


def zap_pre_shutdown(zap):
    print("myhook.py: Printing authentication stats before shutdown...")
    print(zap.stats.site_stats(global_target, "stats.auth"))
