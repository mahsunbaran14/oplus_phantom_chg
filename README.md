# OPlus Phantom Charge / OPlus Hayalet Şarj

`id=oplus_phantom_chg` · Magisk / KernelSU Next · MIT

## Kapsam / Scope

OPlus `oplus_chg` şarj yığını (charging stack) üzerinde hayalet PD
(phantom PD) / batarya askı uyanık kilidi (battery suspend wakelock).

Kontrol noktası: `/proc/charger_cycle` → `unwakelock` / `wakelock`.

- `post-fs-data` → `early.sh` (setsid, boot blok yok, 15 s tavan). `hw_detect` yokken yazmaz. `hw_detect=1` → `wakelock`, aksi `unwakelock` (boot ikonu).
- Kablo / WARP takılı (`hw_detect=1`): `wakelock`
- Hayalet PD (`hw_detect=0` ama `online`/`present` veya VBUS > 3.7 V): `unwakelock`
- Kablo çıkışı (`hw_detect` 1→0): `unwakelock`

DTBO yazmaz. Akım duvarı / watt kilidi kaldırmaz.
ACC veya `oplus-battery-kit` yerine geçmez.

Does not write DTBO. Does not unlock wattage. Not a replacement for ACC.

## Test cihazı / Tested on

- OnePlus 9 LE2115
- crDroid 12.12, Android 16
- KernelSU Next 3.3.0 (kök / root gerekli)

Başka OPlus (OPPO / OnePlus / realme) belki çalışır; `/proc/charger_cycle`
yoksa no-op. Stok OOS doğrulanmadı. Other OPlus untested; stock OOS unverified.

## Kurulum / Install

KSU Next / Magisk → Modules → zip yükle → reboot.
`module.prop` `id` değiştirme.

## Lisans / License

MIT

## Yükleme / Do not ship

- `phantom.log`
- `daemon.pid`
- kişisel ADB / logcat / dumpsys / IMEI
- kanıt dump
