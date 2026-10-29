# Systems Depth — C23, C++23/26, web frontend

Talking points for topic (i) and for LLD and test discussions when the stack
calls for them. Go to memory / UB / ABI level when it changes a decision; skip
it when it does not. Everything version-sensitive here must be **web-confirmed
at dialogue time** (standards and compiler support move every few months).

## Status snapshot (verify before relying on it)

| Standard | Status as of 2026-10 | Confirm at |
|---|---|---|
| C23 | Published as ISO/IEC 9899:2024 (October 2024) | iso.org (search 9899), en.cppreference.com/w/c/23 |
| C++23 | Published as ISO/IEC 14882:2024 | iso.org, en.cppreference.com/w/cpp/23 |
| C++26 | Technically complete at the March 2026 London (Croydon) WG21 meeting; in the DIS ballot / publication pipeline | herbsutter.com trip reports, iso.org/standard/91179, en.cppreference.com/w/cpp/26 |
| Compiler support | Partial and moving (GCC 15 made `gnu23` the default C dialect; C++26 features land per release) | en.cppreference.com/w/cpp/compiler_support, GCC/Clang/MSVC release notes |

## C (C23)

- **New tools that remove whole bug classes:** `nullptr` / `nullptr_t`;
  `constexpr` objects; `typeof`; `<stdckdint.h>` checked arithmetic
  (`ckd_add`, `ckd_sub`, `ckd_mul`) for overflow-safe size math;
  `memset_explicit` for secrets; `[[nodiscard]]`, `[[maybe_unused]]`;
  `_BitInt(N)`; `#embed`; `bool`/`true`/`false` as keywords.
- **UB to discuss explicitly:** signed overflow; out-of-bounds and
  one-past-the-end dereference; use after free and double free; uninitialized
  reads; strict aliasing violations; misaligned access; data races (C11 memory
  model); shifting by ≥ width; `restrict` violations.
- **ABI:** struct layout and padding are part of the ABI once exposed; enum
  size; calling convention; symbol visibility (`-fvisibility=hidden` + explicit
  exports); versioned symbols for shared libraries; never change a public
  struct's layout in a minor release.
- **Test and tooling plan:** `-std=c23 -Wall -Wextra -Wpedantic -Werror`;
  ASan + UBSan on every test run; TSan for concurrency (separate build); MSan
  where available (Clang); libFuzzer or AFL++ harness for every parser; Frama-C
  or CBMC when the core is `fv-eligible`; libabigail `abidiff` in CI for shared
  libraries.

## C++ (C++23, C++26)

- **C++23 worth using:** `std::expected` (error model without exceptions);
  `std::print`; deducing `this`; `std::mdspan`; `std::flat_map`;
  `std::move_only_function`; ranges improvements; `[[assume]]` (dangerous —
  UB if false).
- **C++26 (confirm support first):** static reflection; contracts
  (`pre`, `post`, `contract_assert`); `std::execution` (senders/receivers);
  erroneous behavior for uninitialized reads (defined-but-wrong instead of UB);
  a hardened standard library mode; pack indexing; `std::inplace_vector`;
  `#embed`; `<linalg>`.
- **Memory and lifetime:** ownership by type (`unique_ptr` > `shared_ptr` >
  raw); dangling references from views (`string_view`, `span`, ranges) and
  temporaries; iterator invalidation; object lifetime and `std::launder`;
  move-from states; exception safety guarantees (basic / strong / nothrow) per
  function.
- **UB to discuss explicitly:** everything listed for C, plus ODR violations,
  `reinterpret_cast` aliasing, lifetime of temporaries bound to members,
  `noexcept` functions that throw (terminate), data races on non-atomics.
- **ABI:** `std::string` / `std::list` dual ABI in libstdc++
  (`_GLIBCXX_USE_CXX11_ABI`); inline namespaces for versioning; pimpl for
  stable layouts; never expose STL types across a C ABI boundary; exceptions
  must not cross C boundaries; `[[no_unique_address]]` changes layout.
- **Test and tooling plan:** sanitizers as for C; libstdc++
  `_GLIBCXX_ASSERTIONS` or libc++ hardening modes in test builds; clang-tidy
  (`bugprone-*`, `cppcoreguidelines-*`); fuzz harnesses; `abidiff` for
  libraries; CBMC or ESBMC (bounded) when `fv-eligible`.

## Web frontend

- **Performance budgets as numbers:** Core Web Vitals at the 75th percentile —
  LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 (web.dev/articles/vitals); JS bundle
  budget per route; image and font strategy.
- **Rendering strategy:** CSR vs SSR vs SSG vs streaming vs islands — decide
  from content freshness, SEO need, and time-to-interactive; hydration cost and
  hydration-mismatch risks.
- **State and data:** server state vs client state; cache invalidation;
  optimistic updates and rollback; offline behavior.
- **Accessibility:** WCAG 2.2 AA; keyboard paths; focus management; screen
  reader names; reduced motion. Automated axe checks catch only part of it —
  agree which manual checks run.
- **Security:** XSS sinks and Trusted Types; CSP; CSRF; `SameSite` cookies;
  third-party script inventory; dependency supply chain.
- **Compatibility:** browser support matrix (Baseline, web.dev/baseline);
  progressive enhancement; i18n and RTL.
- **Test plan tags:** `unit` (logic, hooks), `integration` (component with
  real DOM), `e2e` + `a11y` + `visual` for critical journeys, `perf` (Lighthouse
  CI or field data thresholds tied to the budgets above).

## Language-agnostic checklist

Error model · resource lifetimes · concurrency model and memory ordering ·
determinism (clocks, randomness, ordering) · input validation boundary ·
backward compatibility surface · observability hooks · build reproducibility.
