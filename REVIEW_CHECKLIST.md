# Checklist sửa bài theo góp ý (gop_y_sr4rec_softwarex.md)

Cập nhật lần cuối: 2026-09-28. Đã lọc theo phản biện — bỏ A1 (đã xong: chuyển sang
`pip install -e .`, không cần PyPI) và A6 (đã tự resolve, DOI trả HTTP 200).

Tick `[x]` khi xong. Ghi chú kết quả ngay dưới mỗi mục để không phải nhớ/lục lại chat.

---

## Nhóm 1 — Cần BẠN chạy lệnh trên `labai217`

- [ ] **A2 + A3 — Đóng băng `quickstart`, chụp lại transcript Appendix B**
  ```bash
  cd ~/ThaiLe/new_exprerient/software_x_tool
  sr4rec run examples/configs/01_quickstart.yaml
  python scripts/freeze_expected.py runs/<tên_folder_vừa_tạo> quickstart
  ```
  Dán lại đây: nội dung `src/sr4rec/demos/expected/quickstart.yaml` sau khi đóng băng +
  toàn bộ output console của 2 lệnh trên.
  ```
  (dán kết quả vào đây)
  ```

- [ ] **A4 — Thông tin máy tham chiếu thật**
  ```bash
  lscpu | grep "Model name"
  cat /etc/os-release | grep PRETTY_NAME
  python3 -c "import torch; print(torch.__version__, torch.version.cuda)"
  python3 --version
  ```
  Dán lại đây:
  ```
  (dán kết quả vào đây)
  ```

- [ ] **B5 — `requirements.lock`**
  ```bash
  cd ~/ThaiLe/new_exprerient/software_x_tool
  pip freeze > requirements.lock
  cat requirements.lock
  ```
  Dán lại đây:
  ```
  (dán kết quả vào đây)
  ```

---

## Nhóm 2 — Cần BẠN quyết định / cung cấp thông tin (không cần chạy lệnh)

- [ ] **A5 — Tên + ORCID thầy Vinh**
  Hỏi thầy Vinh Truong Hoang xác nhận:
  - Cách tách `given-names` / `family-names` đúng cho `CITATION.cff`?
  - ORCID của thầy Vinh (đăng ký tại orcid.org nếu chưa có)?
  - ORCID của bạn (Thai Le Quang)?
  ```
  (ghi câu trả lời vào đây)
  ```

- [ ] **B6, B7 — Đối chiếu template OSP gốc**
  Mở file "template OSP chính thức" (Linh đang có), kiểm 2 chỗ:
  - Bảng "Current executable software version" (S1–S8) có bắt buộc không hay chỉ optional?
  - Nhãn cột C2 nguyên văn có chữ "GitHub" không: "Permanent GitHub link to code/repository..."?
  ```
  (dán nguyên văn 2 chỗ vào đây)
  ```

---

## Nhóm 3 — Tôi tự viết, chỉ cần bạn duyệt (không cần chạy gì)

- [ ] **B1** — Viết rule verdict tường minh vào §2.2 (dùng ALPHA=0.05, điều kiện CI không chứa 0, giải thích ca D3 1-seed, câu độ nhạy ngưỡng)
- [ ] **B2** — Thêm chú thích vào ô D3 của Table 5 ("significant gain (1 seed, not verified)" hoặc footnote)
- [ ] **B3** — Viết lại đoạn D2, bỏ "therefore" nối ngược logic, dẫn chứng qua D1
- [ ] **B4** — Thêm câu phân biệt tolerance tái lập vs hiệu ứng theo cặp (đoạn Reproduction)
- [ ] **B8** — Bổ sung Impact: 3 câu hỏi nghiên cứu mở + nhắc rõ Table C.1
- [ ] **B9** — Rút gọn abstract (~120-140 từ) + bản ASCII phẳng để dán Editorial Manager
- [ ] **B10** — Thêm nửa câu disclosure EarVN1.0 do đồng tác giả công bố
- [ ] **A5 (DOI)** — Điền concept DOI `10.5281/zenodo.23008428` vào `CITATION.cff` (đã verify resolve OK, làm ngay được)

---

## Làm sau cùng (sau khi Nhóm 1–3 xong hết)

- [ ] Cắt tag `v0.1.2`, tạo Zenodo record mới, cập nhật C1/C2/C3 trong `paper/main.tex`
- [ ] Kiểm lại toàn bộ link công khai (GitHub, GitHub tree, Zenodo DOI) ở chế độ chưa đăng nhập, ngay trước khi bấm nộp
