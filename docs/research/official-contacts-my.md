# Official numbers Jaga tells a Malaysian user to call (ticket #6)

All sources accessed 2026-10-28. Only primary pages (the agency's or bank's own site, or a Malaysian government portal) count.
"Confirmed" means I fetched the page and the number was on it. "UNCONFIRMED" means the direct fetch failed and the
number comes only from a search-engine snippet of that same page.

## Government

| key | agency | number (as published) | for | hours | source |
|---|---|---|---|---|---|
| `nsrc` | National Scam Response Centre | 997 | Real-time help for online financial scams: call within 24 h so the money can be blocked | "Daily (24 hours)" | https://www.malaysia.gov.my/en/categories/safety-and-community/cybersecurity/nsrc-997-hotline (topic updated 31/7/2026) |
| `pdrm` | PDRM / MERS 999 | 999 | Emergencies only, shared with Bomba, hospitals, APM and Maritim | Not stated on the 999 page | https://999.gov.my/mers-999/apa-itu-mers-999/ |
| `pdrm_hq` | PDRM Bukit Aman HQ | +603 - 2266 2222 | General line (site footer) | Not stated | https://www.rmp.gov.my/news-detail/2026/04/27/besmartstayalert-letsfightscammertogether-postings-pilihan-nsrc-997-perangi-jenayah-dan-penipuan |
| `lhdn` | LHDN / HASiL Contact Centre | 603-8911 1000 | Tax enquiries | 9:00 am to 5:00 pm, Mon-Fri, except public holidays | https://www.hasil.gov.my/en/hubungi-kami/meja-bantuan-hasil/ |
| `bnm` | BNM, BNMTELELINK | 1-300-88-5465 (1-300-88-LINK) | Report fraud, scams and illegal financial schemes | Not stated on the fraud page; contact-us page lists "BNMLINK Contact Centre 1-300-88-5465, Monday - Friday 9am - 5pm" | https://www.bnm.gov.my/web/financial-fraud-alert/report-a-fraud ; https://www.bnm.gov.my/contact-us |

### CCID Scam Response Centre: retired
The NFCC NSRC FAQ (Q12) says NSRC has taken over the work CCID used to do. It also says people no longer need to call the
old CCID lines, 03-2610 1559 / 1599, and should call their bank's hotline or 997 instead.
Source: https://nfcc.jpm.gov.my/index.php/en/component/content/article/nsrc-info-link?catid=11&Itemid=114.
No official page I found lists a CCID WhatsApp number, so the WhatsApp line is UNCONFIRMED. Do not ship it.
**Recommendation:** for scams, point users to 997 and their bank, not to CCID.

## Banks (prefer fraud line)

| key | bank | number (as published) | line type | hours | source |
|---|---|---|---|---|---|
| `maybank` | Maybank | +603 5891 4744 | Fraud Hotline | "24 hours a day" | https://www.maybank2u.com.my/maybank2u/malaysia/en/personal/about_us/contact-us.page. Confirmed 2026-10-28. General line: 1-300 88 6688 |
| `cimb` | CIMB | +603 6204 7788 | 24-hour Contact Centre, which CIMB names as the line to call if scammed | 24 hours | https://www.cimb.com.my/en/personal/help-support/security-and-fraud/security-and-fraud-awareness/reporting-instructions-personal.html |
| `public_bank` | Public Bank | 03-21773555 | Report Fraud (Case Management), a dedicated fraud line | 24 hours | https://www.pbebank.com/en/contact-us/ (general line 03-21708000 is office hours only) |
| `rhb` | RHB | 603-9206 8118 | Customer Contact Centre; the site lists no separate fraud line | "Available 24 hours" | https://www.rhbgroup.com/others/contact-us/index.html |
| `hong_leong` | Hong Leong Bank | 03-7626 8899 | HLB Contact Centre for scam/fraud reports | "24 hours Daily" | https://www.hlb.com.my/en/personal-banking/help-support/general-faq/report-a-scam-fraud.html |
| `ambank` | AmBank | 03-2178 8888 | Contact Centre; the site lists no separate fraud line | General hours 9am-9pm daily from 1 Aug 2026; fraud/scam reporting stays 24/7 | https://www.ambank.com.my/home/contact-centre ; https://www.ambankgroup.com/newsroom/announcements/revision-to-ambank-contact-centre-operating-hours |
| `bank_islam` | Bank Islam | +603-26 900 900 | Contact Centre, which also serves as the Fraud Hotline | "24 hours, 7 days a week" | https://www.bankislam.com/need-assistance/contact-us/ |
| `bsn` | BSN | 03-2613 1900 | Contact Centre, "Report Fraud and Scam" | Not stated | https://www.bsn.com.my/page/new-bsn-official-telephone-numbers |

## Conflicts found
- **NSRC hours.** malaysia.gov.my (updated 31/7/2026), the PDRM post of 27/4/2026 and BSN all say 24/7. The NFCC's own FAQ, BNM's
  scam FAQ (https://www.bnm.gov.my/financial-consumers/enquiries/categories/scams/all) and the HLB page still say 8am-8pm.
  These look like stale pages. Show "24 hours" and keep the "if 997 is busy, call your bank" fallback.
- **AmBank hours.** The contact-centre page gives 9am-9pm. The 2026 notice says fraud reporting stays 24/7 but does not name a number.
- **BSN.** 1-300-88-1900 stopped working on 1 Jan 2026. Older BSN pages still list it. Use 03-2613 1900.
- **HASiL.** Old pages call 03-8911 1000 "toll-free" and list an overseas line, +603-8911 1100. The current help-desk page lists neither.
- **BNMTELELINK hours.** The fraud page gives no hours. The contact-us page gives Mon-Fri 9am-5pm, under the label "BNMLINK".

## Maybank confirmed (orchestrator, 2026-10-28)
Maybank Fraud Hotline (24 hours a day): +603 5891 4744, on
https://www.maybank2u.com.my/maybank2u/malaysia/en/personal/about_us/contact-us.page (accessed 2026-10-28).
The same page lists NSRC 997 as 8.00am-8.00pm daily, another stale-hours source.
