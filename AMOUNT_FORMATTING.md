# Formatting the Amount Value

Last updated: December 17, 2025

When you specify an amount in an API request, format the value based on the specified currency to ensure Checkout.com processes the correct amount. For example, when you request a payment or request an authentication session.

## General Requirements

Additionally, the amount value must:
- Be greater than zero
- Not contain decimals
- Not contain more than nine digits

## Currency Multipliers

Depending on the currency, you may need to provide:
1. The full amount
2. The amount divided by 1000
3. The amount divided by 100

---

### 1. The Full Amount (Zero Decimals)

For the following currencies, the amount you specify is the final amount, without any additional calculations. For example, setting `amount` to `100` for `JPY` results in **100 Japanese Yen**.

| Code | Currency Name |
|------|---------------|
| BIF  | Burundian Franc |
| DJF  | Djiboutian Franc |
| GNF  | Guinean Franc |
| ISK  | Icelandic Krona |
| JPY  | Japanese Yen |
| KMF  | Comoran Franc |
| KRW  | South Korean Won |
| PYG  | Paraguayan Guarani |
| RWF  | Rwandan Franc |
| UGX  | Ugandan Shilling |
| VUV  | Vanuatu Vatu |
| VND  | Vietnamese Dong |
| XAF  | Central African Franc |
| XOF  | West African CFA franc |
| XPF  | Comptoirs Français du Pacifique |

**Request Example:**
```json
{
  "amount": 100,
  "currency": "JPY"
}
```

---

### 2. The Amount Divided by 1000 (Three Decimals)

For the following currencies, the amount you specify is divided by 1000 to determine the final amount. For example, setting `amount` to `100000` for `BHD` results in **100 Bahraini Dinar**.

> [!IMPORTANT]
> The last digit must always be a **0**. For example, an amount value of `1001` is invalid for these currencies.

| Code | Currency Name |
|------|---------------|
| BHD  | Bahraini Dinar |
| IQD  | Iraqi Dinar |
| JOD  | Jordanian Dinar |
| KWD  | Kuwaiti Dinar |
| LYD  | Libyan Dinar |
| OMR  | Omani Rial |
| TND  | Tunisian Dinar |

**Request Example:**
```json
{
  "amount": 100000,
  "currency": "BHD"
}
```

---

### 3. The Amount Divided by 100 (Two Decimals)

**For all other currencies** (including USD, EUR, GBP, etc.), the amount you specify is divided by 100 to determine the final amount. For example, setting `amount` to `10000` for `USD` results in **100 US Dollars**.

**Request Example:**
```json
{
  "amount": 10000,
  "currency": "USD"
}
```

> [!NOTE]
> **Chilean Peso (CLP):** For payment requests in CLP, the last two digits of the amount must be `00`. For example, an amount value of `100010` is invalid. This does not apply to authentication requests sent using the Standalone API.
