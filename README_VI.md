# MewRemote Offline Helper — Dopamine RootHide

Mục tiêu của tweak này là dùng đúng **offline fallback đã có sẵn trong MewRemote 3.2**.

MewRemote đã lưu một signed token hợp lệ và `trollvncserver` có sẵn các nhánh:
- `server validation timed out; allowing saved offline token`
- `server unreachable; allowing saved offline token`

Tweak chỉ chặn kết nối tới `licenses.mewit.vn`, để app coi server là unreachable và dùng
signed token đã lưu local.

## Không làm gì
- Không sửa `LicenseToken`
- Không giả chữ ký
- Không thay feature
- Không sửa `LicenseExpiresAt`
- Không biến token hết hạn thành hợp lệ

Vì vậy token hiện tại vẫn bị app kiểm tra chữ ký/device/expiry như bình thường.

## Dùng
1. Đảm bảo key đã Activate thành công ít nhất một lần.
2. Build `.deb` bằng GitHub Actions.
3. Cài `.deb` trên Dopamine RootHide.
4. Respring/userspace reboot.
5. Force-close MewRemote rồi mở lại.
6. Có thể tắt Internet; vẫn giữ Wi-Fi/LAN nếu cần VNC nội bộ.

Log:
`/var/tmp/mewremote_offline.log`

## Tạm tắt helper
Tạo file rỗng:
`/var/tmp/mewremote_offline.disable`

Sau đó force-close/reopen MewRemote (hoặc respring).

Xóa file đó để bật lại.

Nếu cần activate/re-activate key từ server, hãy tạm tắt helper trước.
