echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/product/etc/build.prop"

# --- SD865 Proaktif Termal / Performans Optimizasyonu ---
# CPU peak frekansi %90'a cek: throttle onlenir, tutarli performans saglanir
# Kullanici hicbir fark hissetmez cunku %10 hiz farki algilanamaz
echo "Adding SD865 thermal/performance optimization init script"
mkdir -p "$WORK_DIR/system/system/etc/init"
cat > "$WORK_DIR/system/system/etc/init/mint_perf_optimize.rc" << 'INITEOF'
# MintOS SD865 Performance & Kernel Optimization
# Tum ayarlar sysfs uzerinden, kernel recompile gerektirmez

on property:sys.boot_completed=1

    # ====== CPU Frequency Cap (%90) ======
    # Throttle onleme, tutarli performans, termal headroom +%20-30
    # Prime core (cluster2): 2841600 -> 2553600
    write /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 2553600
    # Big cores (cluster1): 2419200 -> 2169600
    write /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 2169600
    write /sys/devices/system/cpu/cpu5/cpufreq/scaling_max_freq 2169600
    write /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq 2169600
    # Little cores degismez - zaten dusuk guclu

    # ====== I/O Scheduler Optimizasyonu ======
    # Read-ahead: 128KB yeterli, gereksiz bellek tuketimini onler (varsayilan 512-1024)
    write /sys/block/sda/queue/read_ahead_kb 128
    write /sys/block/sdb/queue/read_ahead_kb 128
    write /sys/block/sdc/queue/read_ahead_kb 128
    # I/O istatistik toplama kapali - her I/O isleminde gereksiz CPU cycles harcar
    write /sys/block/sda/queue/iostats 0
    write /sys/block/sdb/queue/iostats 0
    write /sys/block/sdc/queue/iostats 0
    # Nr_requests: kuyruk derinligi - 64 flash storage icin optimal
    write /sys/block/sda/queue/nr_requests 64
    # Rotational: SSD/UFS icin 0 (kernel'e flash storage oldugunu bildir)
    write /sys/block/sda/queue/rotational 0
    write /sys/block/sdb/queue/rotational 0
    write /sys/block/sdc/queue/rotational 0
    # RQ affinity: I/O completion ayni CPU'da yapilsin - cache locality
    write /sys/block/sda/queue/rq_affinity 2
    write /sys/block/sdb/queue/rq_affinity 2
    write /sys/block/sdc/queue/rq_affinity 2
    # Nomerges: ayni bloklara giden I/O isteklerini birlestir (0 = birlestir)
    write /sys/block/sda/queue/nomerges 0

    # ====== Virtual Memory (VM) Optimizasyonu ======
    # Swappiness: 100 = agresif swap (varsayilan 60-100 arasi)
    # Dusuk deger RAM'i tercih eder ama OOM riski artar
    # 80 dengeli: yeterince swap yapar ama gereksiz swap'tan kacinir
    write /proc/sys/vm/swappiness 80
    # Dirty ratio: RAM'in %20'si kirli sayfalara ayrilabilir (varsayilan 20-40)
    write /proc/sys/vm/dirty_ratio 20
    # Dirty background ratio: %5'te arka plan yazma baslasin
    write /proc/sys/vm/dirty_background_ratio 5
    # Dirty writeback: 500cs = 5 saniyede bir kirli sayfalari diske yaz
    write /proc/sys/vm/dirty_writeback_centisecs 500
    # Dirty expire: 200cs = 2 saniye sonra kirli sayfa expire olsun
    write /proc/sys/vm/dirty_expire_centisecs 200
    # VFS cache pressure: 80 = dentry/inode cache'i biraz daha agresif temizle
    # Varsayilan 100, dusuk deger daha fazla RAM'i cache'te tutar
    write /proc/sys/vm/vfs_cache_pressure 80
    # Overcommit: 0 = heuristic (varsayilan, guvenli)
    write /proc/sys/vm/overcommit_memory 0
    # Page-cluster: 0 = tek sayfa swap (varsayilan 3 = 8 sayfa)
    # Daha az gereksiz swap I/O, biraz daha fazla swap fault ama UFS'te sorun degil
    write /proc/sys/vm/page-cluster 0
    # Watermark boost: kapatarak gereksiz memory reclaim onlenir
    write /proc/sys/vm/watermark_boost_factor 0

    # ====== TCP / Network Stack ======
    # BBR congestion control: Google'in modern algoritmasi, daha iyi throughput
    write /proc/sys/net/ipv4/tcp_congestion_control bbr
    # FQ (Fair Queue) scheduler: BBR ile birlikte optimal
    write /proc/sys/net/core/default_qdisc fq
    # TCP fastopen: hem client hem server tarafinda (3 = ikisi birden)
    write /proc/sys/net/ipv4/tcp_fastopen 3
    # TCP buffer sizes: min/default/max (bayt) - LTE/5G icin optimize
    write /proc/sys/net/ipv4/tcp_rmem "4096 131072 6291456"
    write /proc/sys/net/ipv4/tcp_wmem "4096 65536 4194304"
    # ECN: Explicit Congestion Notification acik
    write /proc/sys/net/ipv4/tcp_ecn 1
    # Timestamps kapali: her pakette 12 byte tasarruf, mobilde olculebilir fark
    write /proc/sys/net/ipv4/tcp_timestamps 0

    # ====== Entropy / Random ======
    # Urandom okuma icin minimum entropy: 64 (varsayilan 192)
    # Daha az bloklanma, boot hizi artar, guvenlik riski yok (modern kernellerde)
    write /proc/sys/kernel/random/read_wakeup_threshold 64
    write /proc/sys/kernel/random/write_wakeup_threshold 128

    # ====== Scheduler (kernel task scheduler) ======
    # Sched migration cost: 500us (varsayilan 500000ns = 500us, genelde dogru)
    # Cekirdekler arasi task gocunu kontrol eder
    write /proc/sys/kernel/sched_migration_cost_ns 500000
    # Schedutil rate limit: governor'un ne siklikta frekans degistirebildigi
    # Dusuk deger = daha hizli tepki ama daha fazla overhead
    write /sys/devices/system/cpu/cpufreq/policy0/schedutil/rate_limit_us 500
    write /sys/devices/system/cpu/cpufreq/policy4/schedutil/rate_limit_us 1000
    write /sys/devices/system/cpu/cpufreq/policy7/schedutil/rate_limit_us 1000
INITEOF

# fs_config ve file_context ekle
echo "system/etc/init/mint_perf_optimize.rc 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
echo "/system/etc/init/mint_perf_optimize\.rc u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
