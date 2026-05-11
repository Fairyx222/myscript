import os
import math
import urllib.request
import json
import io
import aiohttp
import discord
from discord.ext import commands
from discord import app_commands, ui
import asyncio
import random
from PIL import Image, ImageDraw, ImageFont

# ── CONFIG ──────────────────────────────────────────
BOT_TOKEN       = ""
LTC_ADDRESS     = "LYG9i1niDEhAL9V48aPMfTtjzHCdr4hizM"
TICKET_CHANNEL  = "🛒│tickets"
TICKET_CATEGORY = "🖥️ NYX PANEL"
STAFF_ROLE_NAME = "Staff"
LOG_CHANNEL     = "📋-logs-ticket"
OWNER_ROLES     = ["Owner", "Co-Owner", "Fondateur", "Co-Fondateur"]

WELCOME_CONFIG_FILE = "welcome_config.json"

# ── HELPER : emoji custom du serveur ─────────────────
# Si l'emoji existe sur le serveur → affiche le vrai emoji
# Sinon → retourne le fallback (emoji unicode ou texte)
def get_emoji(guild: discord.Guild, name: str, fallback: str = "") -> str:
    e = discord.utils.get(guild.emojis, name=name)
    return str(e) if e else fallback

# ── PRIX DYNAMIQUES AVEC EMOJIS ──────────────────────
def build_prices_msg(guild: discord.Guild) -> str:
    robux = get_emoji(guild, "Robux", "🪙")
    ltc   = get_emoji(guild, "LTC",   "💳")
    return (
        f"💰 **Prices:**\n"
        f"• 📅 **Day** — `$2` | `500` {robux}\n"
        f"• 📆 **Week** — `$5` | `1,250` {robux}\n"
        f"• ♾️ **Lifetime** — `$10` | `2,500` {robux} | `$20 Brainrot`\n\n"
        f"{ltc} **LTC Address:**\n`{LTC_ADDRESS}`\n\n"
        f"📸 Send the exact amount then share your transaction screenshot here."
    )

# ── WELCOME CONFIG ───────────────────────────────────
def load_welcome_config() -> dict:
    if os.path.exists(WELCOME_CONFIG_FILE):
        with open(WELCOME_CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def save_welcome_config(data: dict):
    with open(WELCOME_CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# ── GÉNÉRATION BANNIÈRE WELCOME ──────────────────────
def hex_to_rgb(hex_str, fallback="#2B2D31"):
    h = (hex_str or fallback).strip().lstrip("#")
    if len(h) != 6:
        h = fallback.lstrip("#")
    try:
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
    except Exception:
        return tuple(int(fallback.lstrip("#")[i:i+2], 16) for i in (0, 2, 4))

async def generate_welcome_banner(member: discord.Member, cfg: dict) -> discord.File:
    width, height = 900, 300

    accent_color = hex_to_rgb(cfg.get("accent_color"), "#5865F2")
    text_color   = hex_to_rgb(cfg.get("text_color"),   "#FFFFFF")
    sub_color    = hex_to_rgb(cfg.get("sub_color"),     "#B5BAC1")
    bg_color     = hex_to_rgb(cfg.get("bg_color"),      "#1a1b2e")
    bg_color2    = hex_to_rgb(cfg.get("bg_color2", cfg.get("bg_color", "#1a1b2e")), "#1a1b2e")
    bg_type      = cfg.get("bg_type", "solid")

    name          = member.display_name
    server        = member.guild.name
    count         = str(member.guild.member_count)
    title_text    = cfg.get("title",    "Welcome to {server}!").replace("{user}", name).replace("{server}", server).replace("{count}", count)
    subtitle_text = cfg.get("subtitle", "@{user}").replace("{user}", name).replace("{server}", server).replace("{count}", count)
    footer_text   = cfg.get("footer",   "Member #{count}").replace("{user}", name).replace("{server}", server).replace("{count}", count)

    img = Image.new("RGB", (width, height), color=bg_color)

    # Dégradé
    if bg_type == "gradient" and bg_color != bg_color2:
        angle_rad = math.radians(float(cfg.get("bg_angle", 135)))
        cos_a     = math.cos(angle_rad)
        sin_a     = math.sin(angle_rad)
        proj_max  = abs(cos_a) * width + abs(sin_a) * height
        pixels    = img.load()
        for py in range(height):
            for px in range(width):
                t = max(0.0, min(1.0, (px * cos_a + py * sin_a) / proj_max))
                pixels[px, py] = (
                    int(bg_color[0] + (bg_color2[0] - bg_color[0]) * t),
                    int(bg_color[1] + (bg_color2[1] - bg_color[1]) * t),
                    int(bg_color[2] + (bg_color2[2] - bg_color[2]) * t),
                )

    draw = ImageDraw.Draw(img)

    # Barres accent
    draw.rectangle([(0, 0), (6, height)], fill=accent_color)
    draw.rectangle([(0, height - 4), (width, height)], fill=accent_color)

    # Avatar
    avatar_size = int(cfg.get("avatar_size", 120))
    avatar_x    = int(cfg.get("avatar_x", 50))
    avatar_y    = int(cfg.get("avatar_y", (height - avatar_size) // 2))

    draw.ellipse(
        [(avatar_x, avatar_y), (avatar_x + avatar_size, avatar_y + avatar_size)],
        outline=accent_color, width=4,
        fill=tuple(max(0, c - 30) for c in bg_color)
    )
    try:
        avatar_url = str(member.display_avatar.with_size(128).with_format("png"))
        async with aiohttp.ClientSession() as session:
            async with session.get(avatar_url) as resp:
                avatar_bytes = await resp.read()
        avatar_img = Image.open(io.BytesIO(avatar_bytes)).convert("RGBA").resize((avatar_size, avatar_size))
        mask       = Image.new("L", (avatar_size, avatar_size), 0)
        mask_draw  = ImageDraw.Draw(mask)
        mask_draw.ellipse([(0, 0), (avatar_size, avatar_size)], fill=255)
        img.paste(avatar_img, (avatar_x, avatar_y), mask)
    except Exception:
        pass

    # Textes
    title_x    = int(cfg.get("title_x", avatar_x + avatar_size + 30))
    title_y    = int(cfg.get("title_y", 80))
    title_size = int(cfg.get("title_size", 42))

    font_bold    = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
    ]
    font_regular = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "C:/Windows/Fonts/arial.ttf",
    ]

    font_title = ImageFont.load_default()
    font_sub   = ImageFont.load_default()
    font_foot  = ImageFont.load_default()

    for p in font_bold:
        if os.path.exists(p):
            try: font_title = ImageFont.truetype(p, title_size); break
            except: pass
    for p in font_regular:
        if os.path.exists(p):
            try: font_sub = ImageFont.truetype(p, 24); font_foot = ImageFont.truetype(p, 18); break
            except: pass

    draw.text((title_x, title_y),                   title_text,    font=font_title, fill=text_color)
    draw.text((title_x, title_y + title_size + 10), subtitle_text, font=font_sub,   fill=sub_color)
    draw.text((title_x, height - 35),               footer_text,   font=font_foot,  fill=sub_color)

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return discord.File(buf, filename="welcome.png")

# ── DÉTECTION LANGUE ────────────────────────────────
LANG_KW = {
    "fr": ["bonjour","salut","bonsoir","merci","comment","payer","prix","aide","svp","stp","coucou","oui","non","acheter","re"],
    "es": ["hola","buenos","gracias","como","precio","pagar","ayuda","por favor","buenas","si","no","comprar"],
    "de": ["hallo","guten","danke","wie","preis","kaufen","hilfe","bitte","ja","nein"],
    "pt": ["olá","ola","bom","obrigado","como","preço","pagar","ajuda","por favor","sim","nao"],
    "ar": ["مرحبا","السلام","شكرا","كيف","سعر","دفع","مساعدة","نعم","لا"],
    "ru": ["привет","здравствуй","спасибо","как","цена","купить","помощь","пожалуйста","да","нет"],
    "zh": ["你好","谢谢","怎么","价格","购买","帮助","是","不"],
    "ja": ["こんにちは","ありがとう","どうやって","価格","購入","助けて","はい","いいえ"],
    "it": ["ciao","buongiorno","grazie","come","prezzo","pagare","aiuto","per favore","si","no"],
}

def detect_lang(text: str) -> str:
    t = text.lower()
    scores = {lang: sum(1 for kw in kws if kw in t) for lang, kws in LANG_KW.items()}
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "en"

GREETINGS = {
    "fr": ["Bonjour !", "Salut !", "Bonsoir !"],
    "en": ["Hello!", "Hey!", "Hi there!"],
    "es": ["¡Hola!", "¡Buenas!", "¡Hey!"],
    "de": ["Hallo!", "Hey!", "Guten Tag!"],
    "pt": ["Olá!", "Oi!", "Hey!"],
    "ar": ["مرحباً!", "أهلاً!"],
    "ru": ["Привет!", "Здравствуй!"],
    "zh": ["你好！", "嗨！"],
    "ja": ["こんにちは！", "やあ！"],
    "it": ["Ciao!", "Buongiorno!"],
}
THANKS_REPLY = {
    "fr": "De rien ! 😊 N'hésite pas si tu as d'autres questions.",
    "en": "You're welcome! 😊 Feel free to ask if you have more questions.",
    "es": "¡De nada! 😊",
    "de": "Gern geschehen! 😊",
    "pt": "De nada! 😊",
    "ar": "على الرحب والسعة! 😊",
    "ru": "Пожалуйста! 😊",
    "zh": "不客气！😊",
    "ja": "どういたしまして！😊",
    "it": "Prego! 😊",
}
PRICE_Q_REPLY = {
    "fr": "Bien sûr ! Voici nos tarifs et comment payer :",
    "en": "Sure! Here are our prices and how to pay:",
    "es": "¡Claro! Aquí están nuestros precios:",
    "de": "Natürlich! Hier sind unsere Preise:",
    "pt": "Claro! Aqui estão nossos preços:",
    "ar": "بالطبع! إليك أسعارنا:",
    "ru": "Конечно! Вот наши цены:",
    "zh": "当然！这是我们的价格：",
    "ja": "もちろん！こちらが料金です：",
    "it": "Certo! Ecco i nostri prezzi:",
}
PAYMENT_ASK_TXID = {
    "fr": "📋 Merci ! Envoie-moi ton **TX ID** (64 caractères) pour que je vérifie ta transaction.",
    "en": "📋 Thanks! Send me your **TX ID** (64 characters) so I can verify your transaction.",
    "es": "📋 ¡Gracias! Envíame tu **TX ID** (64 caracteres).",
    "de": "📋 Danke! Sende mir deine **TX ID** (64 Zeichen).",
    "pt": "📋 Obrigado! Envie-me seu **TX ID** (64 caracteres).",
    "ar": "📋 شكراً! أرسل لي **TX ID** (64 حرفاً).",
    "ru": "📋 Спасибо! Пришли **TX ID** (64 символа).",
    "zh": "📋 谢谢！请发送您的 **TX ID**（64个字符）。",
    "ja": "📋 ありがとう！**TX ID**（64文字）を送ってください。",
    "it": "📋 Grazie! Inviami il tuo **TX ID** (64 caratteri).",
}
CLOSE_REPLY = {
    "fr": "🔒 Fermeture du ticket...",
    "en": "🔒 Closing ticket...",
    "es": "🔒 Cerrando el ticket...",
    "de": "🔒 Ticket wird geschlossen...",
    "pt": "🔒 Fechando o ticket...",
    "ar": "🔒 إغلاق التذكرة...",
    "ru": "🔒 Закрытие тикета...",
    "zh": "🔒 关闭工单...",
    "ja": "🔒 チケットを閉じます...",
    "it": "🔒 Chiusura del ticket...",
}
GENERIC_REPLY = {
    "fr": "Je suis là pour t'aider ! 😊 Tu veux connaître nos prix ou tu as une autre question ?",
    "en": "I'm here to help! 😊 Do you want to know our prices or do you have another question?",
    "es": "¡Estoy aquí para ayudarte! 😊",
    "de": "Ich bin hier, um zu helfen! 😊",
    "pt": "Estou aqui para ajudar! 😊",
    "ar": "أنا هنا للمساعدة! 😊",
    "ru": "Я здесь, чтобы помочь! 😊",
    "zh": "我在这里帮助您！😊",
    "ja": "お手伝いします！😊",
    "it": "Sono qui per aiutarti! 😊",
}
HOWRU_REPLY = {
    "fr": "Je vais très bien merci ! 😊 Et toi ? Comment puis-je t'aider ?",
    "en": "I'm doing great thanks! 😊 How about you? How can I help you today?",
    "es": "¡Muy bien gracias! 😊 ¿Y tú?",
    "de": "Mir geht es super, danke! 😊",
    "pt": "Estou muito bem obrigado! 😊",
    "ar": "أنا بخير شكراً! 😊",
    "ru": "Всё отлично, спасибо! 😊",
    "zh": "我很好谢谢！😊",
    "ja": "元気です！😊",
    "it": "Sto benissimo grazie! 😊",
}

GREETING_KW     = ["bonjour","salut","bonsoir","coucou","hello","hi","hey","hola","buenos","hallo","guten","olá","ola","مرحبا","السلام","привет","здравствуй","你好","こんにちは","ciao","buongiorno","yo","sup","re","bsr"]
HOWRU_KW        = ["comment vas","ça va","ca va","how are you","how r u","wie geht","come stai","como estas","como estás","كيف حالك","как дела","你好吗","元気"]
THANKS_KW       = ["merci","thank","gracias","danke","obrigado","شكرا","спасибо","谢谢","ありがとう","grazie","thx","ty","np"]
HOW_TO_BUY_KW   = ["how to buy","how can i buy","how do i buy","how to pay","how can i pay","how do i pay","how to purchase","how to order","how to get","want to buy","i want to buy","i wanna buy","how much","what are the prices","show prices","show me prices","what does it cost","comment acheter","comment payer","comment commander","je veux acheter","comment ça marche","combien ça coûte","c'est combien","les prix","voir les prix","comment je peux payer","comment je peux acheter","como comprar","como pagar","quiero comprar","cuanto cuesta","ver precios","wie kaufen","wie bezahlen","kaufen","was kostet","quero comprar","quanto custa","ver preços","как купить","как оплатить","хочу купить","сколько стоит","如何购买","如何付款","我想买","多少钱","价格","どうやって買う","どうやって払う","買いたい","いくら","كيف أشتري","كيف أدفع","أريد الشراء","كم التكلفة","come comprare","come pagare","voglio comprare","quanto costa","mostra prezzi"]
ALREADY_BOUGHT_KW=["have buy","have bought","bought","i bought","i've bought","i already paid","already paid","already buy","j'ai acheté","j'ai payé","ya compré","bereits gekauft","já comprei","i buying","i buy before","buy before","i have buy","buy its good","i buy","i paid","he pagado","ich habe bezahlt","ho pagato","я оплатил","我付了","支払った"]
PAYMENT_KW      = ["paid","payed","payé","pagué","bezahlt","pagato","оплатил","支払","transaction","screenshot","capture","proof","preuve","envoyé","sent","done","payment","paiement"]
CLOSE_KW        = ["close","fermer","schließen","chiudi","cerrar","fechar","закрыть","閉じる","关闭","terminé","fertig","finito","fin","end"]

def detect_intent(text: str) -> str:
    t = text.lower()
    if any(w in t for w in ALREADY_BOUGHT_KW): return "payment"
    if any(w in t for w in HOW_TO_BUY_KW):    return "how_to_buy"
    if any(w in t for w in CLOSE_KW):          return "close"
    if any(w in t for w in PAYMENT_KW):        return "payment"
    if any(w in t for w in THANKS_KW):         return "thanks"
    if any(w in t for w in HOWRU_KW):          return "howru"
    if any(w in t for w in GREETING_KW):       return "greeting"
    return "generic"

def check_ltc_tx(txid: str) -> str:
    try:
        url = f"https://api.blockcypher.com/v1/ltc/main/txs/{txid}"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read())
        total         = data.get("total", 0) / 1e8
        confirmations = data.get("confirmations", 0)
        outputs       = data.get("outputs", [])
        addresses     = [a for o in outputs for a in o.get("addresses", [])]
        if LTC_ADDRESS not in addresses:
            return "⚠️ Transaction found but **not sent to our LTC address**. Please verify."
        status = "✅ Confirmed" if confirmations >= 1 else "⏳ Pending (0 confirmations)"
        return (f"🔍 **Transaction verified!**\n• Amount: `{total:.8f} LTC`\n• Confirmations: `{confirmations}`\n• Status: {status}\n• To our address: ✅\n\nA staff member will activate your access shortly!")
    except Exception as e:
        return f"❌ Could not verify transaction. Make sure the TX ID is correct. (Error: {e})"

# ── BOT ─────────────────────────────────────────────
intents = discord.Intents.default()
intents.message_content = True
intents.guilds          = True
intents.members         = True

bot      = commands.Bot(command_prefix="!", intents=intents)
welcomed = set()

# ══════════════════════════════════════════════════════
#  /welcomeconfig
# ══════════════════════════════════════════════════════

@bot.tree.command(name="welcomeconfig", description="Configure la bannière de bienvenue")
@app_commands.checks.has_permissions(administrator=True)
async def welcomeconfig(interaction: discord.Interaction):
    all_cfg = load_welcome_config()
    cfg     = all_cfg.get(str(interaction.guild.id), {})

    class WelcomeModal(ui.Modal, title="Welcome Banner Config"):
        w_channel  = ui.TextInput(label="Channel name", default=cfg.get("channel", "bienvenue"), required=True, max_length=100)
        w_title    = ui.TextInput(label="Title ({user}, {server})", default=cfg.get("title", "Welcome to {server}!"), required=True, max_length=80)
        w_subtitle = ui.TextInput(label="Subtitle", default=cfg.get("subtitle", "@{user}"), required=True, max_length=100)
        w_footer   = ui.TextInput(label="Footer ({count})", default=cfg.get("footer", "Member #{count}"), required=True, max_length=80)
        w_colors   = ui.TextInput(
            label="Colors: bg,accent,text,subtitle (hex)",
            default=f"{cfg.get('bg_color','#1a1b2e')},{cfg.get('accent_color','#5865F2')},{cfg.get('text_color','#FFFFFF')},{cfg.get('sub_color','#B5BAC1')}",
            required=True, max_length=100
        )

        async def on_submit(self, interaction: discord.Interaction):
            await interaction.response.defer(ephemeral=True)
            colors_raw = [c.strip() for c in self.w_colors.value.split(",")]
            if len(colors_raw) < 4:
                colors_raw += ["#B5BAC1"] * (4 - len(colors_raw))
            cfg_new = {
                "guild_id":     interaction.guild.id,
                "enabled":      True,
                "channel":      self.w_channel.value.strip().lstrip("#"),
                "title":        self.w_title.value,
                "subtitle":     self.w_subtitle.value,
                "footer":       self.w_footer.value,
                "bg_color":     colors_raw[0],
                "accent_color": colors_raw[1],
                "text_color":   colors_raw[2],
                "sub_color":    colors_raw[3],
            }
            all_cfg2 = load_welcome_config()
            all_cfg2[str(interaction.guild.id)] = cfg_new
            save_welcome_config(all_cfg2)
            try:
                preview = await generate_welcome_banner(interaction.user, cfg_new)
                embed = discord.Embed(title="✅ Welcome config saved!", color=int(cfg_new['accent_color'].lstrip("#"), 16))
                embed.description = f"**Channel:** `#{cfg_new['channel']}`\n**Title:** {cfg_new['title']}\n**Subtitle:** {cfg_new['subtitle']}\n\n🖼️ **Preview:**"
                embed.set_image(url="attachment://welcome.png")
                await interaction.followup.send(embed=embed, file=preview, ephemeral=True)
            except Exception as e:
                await interaction.followup.send(f"✅ Config saved! (Preview error: {e})", ephemeral=True)

    class OpenView(ui.View):
        def __init__(self): super().__init__(timeout=60)
        @ui.button(label="🎨 Open configurator", style=discord.ButtonStyle.blurple)
        async def open_modal(self, inter: discord.Interaction, button: ui.Button):
            await inter.response.send_modal(WelcomeModal())

    embed = discord.Embed(title="🎨 Welcome Banner Configurator", color=0x5865F2,
        description="La config actuelle vient de `welcome_config.json`.\n\n**Placeholders:** `{user}` `{server}` `{count}`")
    await interaction.response.send_message(embed=embed, view=OpenView(), ephemeral=True)


# ══════════════════════════════════════════════════════
#  /activatewelcome
# ══════════════════════════════════════════════════════

@bot.tree.command(name="activatewelcome", description="Active la config de bienvenue")
@app_commands.checks.has_permissions(administrator=True)
async def activatewelcome(interaction: discord.Interaction):
    all_cfg  = load_welcome_config()
    guild_id = str(interaction.guild.id)

    if guild_id not in all_cfg:
        await interaction.response.send_message(
            "❌ Aucune config trouvée pour ce serveur dans `welcome_config.json`.\nAssure-toi que le `guild_id` correspond à ce serveur.",
            ephemeral=True
        )
        return

    cfg = all_cfg[guild_id]
    cfg["enabled"] = True
    all_cfg[guild_id] = cfg
    save_welcome_config(all_cfg)

    channel_name = cfg.get("channel", "")
    channel = discord.utils.get(interaction.guild.text_channels, name=channel_name)
    if not channel:
        channel = discord.utils.find(lambda c: channel_name.lower() in c.name.lower(), interaction.guild.text_channels)

    embed = discord.Embed(title="✅ Bienvenue ACTIVÉ !", color=int(cfg.get("accent_color", "#5865F2").lstrip("#"), 16))
    embed.add_field(name="Salon",  value=channel.mention if channel else f"`#{channel_name}` ⚠️ introuvable", inline=True)
    embed.add_field(name="Titre",  value=cfg.get("title", "?"), inline=False)
    embed.add_field(name="Status", value="🟢 Actif", inline=True)
    embed.set_footer(text="Le bot enverra la bannière à chaque nouveau membre.")

    try:
        preview = await generate_welcome_banner(interaction.user, cfg)
        embed.set_image(url="attachment://welcome.png")
        await interaction.response.send_message(embed=embed, file=preview, ephemeral=True)
    except Exception as e:
        embed.set_footer(text=f"Preview error: {e}")
        await interaction.response.send_message(embed=embed, ephemeral=True)


# ══════════════════════════════════════════════════════
#  /disablewelcome  ← NOUVEAU
# ══════════════════════════════════════════════════════

@bot.tree.command(name="disablewelcome", description="Désactive le message de bienvenue")
@app_commands.checks.has_permissions(administrator=True)
async def disablewelcome(interaction: discord.Interaction):
    all_cfg  = load_welcome_config()
    guild_id = str(interaction.guild.id)

    if guild_id not in all_cfg:
        await interaction.response.send_message(
            "❌ Aucune config trouvée. Utilise `/activatewelcome` d'abord.",
            ephemeral=True
        )
        return

    all_cfg[guild_id]["enabled"] = False
    save_welcome_config(all_cfg)

    embed = discord.Embed(
        title="🔕 Bienvenue DÉSACTIVÉ",
        description="Le bot n'enverra plus de bannière de bienvenue.\nUtilise `/activatewelcome` pour réactiver.",
        color=0xED4245
    )
    embed.add_field(name="Status", value="🔴 Inactif", inline=True)
    await interaction.response.send_message(embed=embed, ephemeral=True)


# ── EVENT : membre qui rejoint ───────────────────────
@bot.event
async def on_member_join(member: discord.Member):
    all_cfg = load_welcome_config()
    cfg     = all_cfg.get(str(member.guild.id))

    # Vérifie que le welcome est activé
    if not cfg or not cfg.get("enabled", True):
        return

    channel_name = cfg.get("channel", "")
    channel = discord.utils.get(member.guild.text_channels, name=channel_name)
    if not channel:
        channel = discord.utils.find(lambda c: channel_name.lower() in c.name.lower(), member.guild.text_channels)
    if not channel:
        return

    try:
        banner = await generate_welcome_banner(member, cfg)
        name   = member.display_name
        server = member.guild.name
        count  = str(member.guild.member_count)
        title  = cfg.get("title",    "Welcome to {server}!").replace("{user}", name).replace("{server}", server).replace("{count}", count)
        sub    = cfg.get("subtitle", "@{user}").replace("{user}", name).replace("{server}", server).replace("{count}", count)
        footer = cfg.get("footer",   "Member #{count}").replace("{user}", name).replace("{server}", server).replace("{count}", count)

        embed = discord.Embed(title=title, description=sub, color=int(cfg.get("accent_color", "#5865F2").lstrip("#"), 16))
        embed.set_image(url="attachment://welcome.png")
        embed.set_footer(text=footer)
        await channel.send(content=member.mention, embed=embed, file=banner)
    except Exception as e:
        print(f"[Welcome] Erreur: {e}")
        await channel.send(f"👋 Bienvenue {member.mention} sur **{member.guild.name}** !")


# ══════════════════════════════════════════════════════
#  TICKET SYSTEM
# ══════════════════════════════════════════════════════

class TicketModal(ui.Modal, title="Open a Support Ticket"):
    reason = ui.TextInput(
        label="Why are you opening this ticket?",
        placeholder="e.g. I want to buy a day subscription, I have a question...",
        style=discord.TextStyle.paragraph,
        required=True,
        max_length=500,
    )

    async def on_submit(self, interaction: discord.Interaction):
        guild = interaction.guild
        user  = interaction.user

        category = discord.utils.get(guild.categories, name=TICKET_CATEGORY)
        if not category:
            category = await guild.create_category(TICKET_CATEGORY)

        staff_role = (
            discord.utils.get(guild.roles, name=STAFF_ROLE_NAME) or
            discord.utils.get(guild.roles, name="Admin") or
            discord.utils.get(guild.roles, name="Administrator")
        )
        overwrites = {
            guild.default_role: discord.PermissionOverwrite(read_messages=False),
            user: discord.PermissionOverwrite(read_messages=True, send_messages=True),
        }
        if staff_role:
            overwrites[staff_role] = discord.PermissionOverwrite(read_messages=True, send_messages=True)

        chan_name = f"ticket-{user.name.lower().replace(' ', '-')[:20]}"
        channel   = await guild.create_text_channel(chan_name, category=category, overwrites=overwrites)

        await interaction.response.send_message(
            f"✅ Your ticket has been created: {channel.mention} — waiting for staff approval.",
            ephemeral=True
        )

        await channel.set_permissions(user, read_messages=True, send_messages=False)
        desc = (
            "⏳ **Your ticket is pending staff approval.**\n"
            "A staff member will accept or refuse it shortly.\n\n"
            "📝 **Your reason:** " + self.reason.value
        )
        wait_embed = discord.Embed(title="🎫 Ticket Created", description=desc, color=0xF0B132)
        wait_embed.set_footer(text="Please wait • Do not leave this channel")
        await channel.send(f"{user.mention}", embed=wait_embed)

        log_ch = discord.utils.get(guild.text_channels, name=LOG_CHANNEL)
        if log_ch:
            log_embed = discord.Embed(title="📋 New Ticket", color=0xF0B132)
            log_embed.add_field(name="Status",  value="⏳ Pending",                      inline=False)
            log_embed.add_field(name="User",    value=f"{user.mention} (`{user.name}`)", inline=True)
            log_embed.add_field(name="Channel", value=channel.mention,                   inline=True)
            log_embed.add_field(name="Reason",  value=self.reason.value,                 inline=False)
            log_embed.set_footer(text=f"Ticket ID: {channel.id}")
            await log_ch.send(embed=log_embed, view=LogView(channel.id, user.id))
        elif staff_role:
            await channel.send(f"📢 {staff_role.mention} — new ticket pending approval!")


class OpenTicketButton(ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    @ui.button(label="📩 Open a Ticket", style=discord.ButtonStyle.blurple, custom_id="open_ticket")
    async def open_ticket(self, interaction: discord.Interaction, button: ui.Button):
        await interaction.response.send_modal(TicketModal())


class LogView(ui.View):
    def __init__(self, ticket_channel_id: int, user_id: int):
        super().__init__(timeout=None)
        self.ticket_channel_id = ticket_channel_id
        self.user_id           = user_id

    @ui.button(label="✅ Accept", style=discord.ButtonStyle.green, custom_id="log_accept")
    async def accept(self, interaction: discord.Interaction, button: ui.Button):
        guild   = interaction.guild
        channel = guild.get_channel(self.ticket_channel_id)
        if not channel:
            await interaction.response.send_message("❌ Ticket channel not found.", ephemeral=True); return
        user = guild.get_member(self.user_id)
        if user:
            await channel.set_permissions(user, read_messages=True, send_messages=True)
        await channel.send(f"✅ Your ticket has been **accepted** by {interaction.user.mention}! How can we help you?")
        welcomed.add(channel.id)
        ctrl_embed = discord.Embed(description="Use the buttons below to manage this ticket.", color=0x2B2D31)
        await channel.send(embed=ctrl_embed, view=TicketView())
        embed = interaction.message.embeds[0]
        embed.color = 0x23A55A
        embed.set_field_at(0, name="Status", value=f"✅ Accepted by {interaction.user.mention}", inline=False)
        await interaction.message.edit(embed=embed, view=None)
        await interaction.response.send_message("✅ Ticket accepted!", ephemeral=True)

    @ui.button(label="❌ Refuse", style=discord.ButtonStyle.red, custom_id="log_refuse")
    async def refuse(self, interaction: discord.Interaction, button: ui.Button):
        guild   = interaction.guild
        channel = guild.get_channel(self.ticket_channel_id)
        if not channel:
            await interaction.response.send_message("❌ Ticket channel not found.", ephemeral=True); return
        msg = await channel.send(f"❌ Your ticket has been **refused** by {interaction.user.mention}. Closing in **9** seconds...")
        for i in range(8, 0, -1):
            await asyncio.sleep(1)
            await msg.edit(content=f"❌ Refused. Closing in **{i}** seconds...")
        await asyncio.sleep(1)
        welcomed.discard(channel.id)
        await channel.delete()
        embed = interaction.message.embeds[0]
        embed.color = 0xF23F42
        embed.set_field_at(0, name="Status", value=f"❌ Refused by {interaction.user.mention}", inline=False)
        await interaction.message.edit(embed=embed, view=None)
        await interaction.response.send_message("❌ Ticket refused and closed.", ephemeral=True)

    @ui.button(label="🔓 Reopen", style=discord.ButtonStyle.blurple, custom_id="log_reopen")
    async def reopen(self, interaction: discord.Interaction, button: ui.Button):
        guild   = interaction.guild
        channel = guild.get_channel(self.ticket_channel_id)
        if not channel:
            await interaction.response.send_message("❌ Ticket channel not found.", ephemeral=True); return
        user = guild.get_member(self.user_id)
        if user:
            await channel.set_permissions(user, read_messages=True, send_messages=True)
        welcomed.add(channel.id)
        await channel.send(f"🔓 Ticket **reopened** by {interaction.user.mention}!")
        embed = interaction.message.embeds[0]
        embed.color = 0x5865F2
        embed.set_field_at(0, name="Status", value=f"🔓 Reopened by {interaction.user.mention}", inline=False)
        await interaction.message.edit(embed=embed, view=None)
        await interaction.response.send_message("🔓 Ticket reopened!", ephemeral=True)


class TicketView(ui.View):
    def __init__(self):
        super().__init__(timeout=None)

    @ui.button(label="🔒 Close Ticket", style=discord.ButtonStyle.red, custom_id="close_ticket")
    async def close_ticket(self, interaction: discord.Interaction, button: ui.Button):
        channel = interaction.channel
        await interaction.response.defer()
        msg = await channel.send("🔒 Closing in **19** seconds...")
        for i in range(18, 0, -1):
            await asyncio.sleep(1)
            await msg.edit(content=f"🔒 Closing in **{i}** seconds...")
        await asyncio.sleep(1)
        welcomed.discard(channel.id)
        await channel.delete()

    @ui.button(label="🔓 Reopen", style=discord.ButtonStyle.green, custom_id="reopen_ticket")
    async def reopen_ticket(self, interaction: discord.Interaction, button: ui.Button):
        channel = interaction.channel
        for target, perms in channel.overwrites.items():
            if isinstance(target, discord.Member) and perms.read_messages:
                await channel.set_permissions(target, read_messages=True, send_messages=True)
        await interaction.response.send_message("✅ Ticket reopened!")


# ══════════════════════════════════════════════════════
#  /ticketconfig — EMBED AVEC EMOJIS CUSTOM DU SERVEUR
# ══════════════════════════════════════════════════════

@bot.tree.command(name="ticketconfig", description="Setup the ticket panel in the current channel")
@app_commands.checks.has_permissions(administrator=True)
async def ticketconfig(interaction: discord.Interaction):
    async for msg in interaction.channel.history(limit=50):
        if msg.author == interaction.guild.me and msg.embeds and msg.components:
            await interaction.response.send_message("❌ A panel already exists! Delete it first.", ephemeral=True)
            return

    guild  = interaction.guild
    robux  = get_emoji(guild, "Robux",    "🪙")
    ltc    = get_emoji(guild, "LTC",      "💳")
    e_day  = get_emoji(guild, "Day",      "📅")
    e_week = get_emoji(guild, "Week",     "📆")
    e_life = get_emoji(guild, "Lifetime", "♾️")

    embed = discord.Embed(
        title="🛒  Support & Shop",
        description=(
            "**Need help or want to purchase?**\n"
            "Open a private ticket and we'll assist you right away.\n"
            "We respond in **any language** in under 5 minutes.\n\n"
            "━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"💰 **Prices**\n"
            f"┣ {e_day} **Day** — `$2` | `500` {robux}\n"
            f"┣ {e_week} **Week** — `$5` | `1,250` {robux}\n"
            f"┗ {e_life} **Lifetime** — `$10` | `2,500` {robux} | `$20 Brainrot`\n\n"
            "━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"{ltc} **Payment — LTC (Litecoin)**\n`{LTC_ADDRESS}`\n\n"
            "📸 Send the exact amount + transaction screenshot in your ticket."
        ),
        color=0x5865F2
    )
    embed.set_footer(text="🌐 Any language • ⚡ < 5 min response • 🔒 Private ticket")
    await interaction.channel.send(embed=embed, view=OpenTicketButton())
    await interaction.response.send_message("✅ Panel created!", ephemeral=True)


@bot.tree.command(name="close", description="Close this ticket")
async def close(interaction: discord.Interaction):
    channel = interaction.channel
    if not (hasattr(channel, "category") and channel.category and TICKET_CATEGORY.lower() in channel.category.name.lower()):
        await interaction.response.send_message("❌ This command only works in a ticket.", ephemeral=True)
        return
    msg = await interaction.channel.send(CLOSE_REPLY["en"])
    await interaction.response.send_message("🔒 Closing...", ephemeral=True)
    for i in range(19, 0, -1):
        await asyncio.sleep(1)
        await msg.edit(content=f"🔒 Closing in **{i}** seconds...")
    await asyncio.sleep(1)
    welcomed.discard(channel.id)
    await channel.delete()


# ── RÉPONSES AUTO ────────────────────────────────────
@bot.event
async def on_message(message: discord.Message):
    if message.author.bot:
        return

    channel   = message.channel
    is_ticket = (
        hasattr(channel, "category") and
        channel.category is not None and
        TICKET_CATEGORY.lower() in channel.category.name.lower()
    )

    if not is_ticket:
        await bot.process_commands(message)
        return

    if channel.id not in welcomed:
        await bot.process_commands(message)
        return

    text = message.content.strip()
    if not text:
        await bot.process_commands(message)
        return

    if len(text) == 64 and all(c in '0123456789abcdefABCDEF' for c in text):
        async with channel.typing():
            result = check_ltc_tx(text)
        await channel.send(result)
        await bot.process_commands(message)
        return

    lang   = detect_lang(text)
    intent = detect_intent(text)

    async with channel.typing():
        await asyncio.sleep(0.8)

    if intent == "howru":
        await channel.send(HOWRU_REPLY.get(lang, HOWRU_REPLY["en"]))
    elif intent == "greeting":
        await channel.send(random.choice(GREETINGS.get(lang, GREETINGS["en"])))
    elif intent == "thanks":
        await channel.send(THANKS_REPLY.get(lang, THANKS_REPLY["en"]))
    elif intent == "how_to_buy":
        intro = PRICE_Q_REPLY.get(lang, PRICE_Q_REPLY["en"])
        embed = discord.Embed(description=build_prices_msg(message.guild), color=0x5865F2)
        await channel.send(intro, embed=embed)
        await asyncio.sleep(1)
        await channel.send(PAYMENT_ASK_TXID.get(lang, PAYMENT_ASK_TXID["en"]))
    elif intent == "payment":
        await channel.send(PAYMENT_ASK_TXID.get(lang, PAYMENT_ASK_TXID["en"]))
        staff_role = (
            discord.utils.get(message.guild.roles, name=STAFF_ROLE_NAME) or
            discord.utils.get(message.guild.roles, name="Admin") or
            discord.utils.get(message.guild.roles, name="Administrator")
        )
        if staff_role:
            await channel.send(f"🔔 {staff_role.mention} — paiement signalé, en attente du TX ID.")
    elif intent == "close":
        msg = await channel.send(CLOSE_REPLY.get(lang, CLOSE_REPLY["en"]))
        for i in range(19, 0, -1):
            await asyncio.sleep(1)
            await msg.edit(content=f"🔒 Closing in **{i}**...")
        await asyncio.sleep(1)
        welcomed.discard(channel.id)
        await channel.delete()
    else:
        await channel.send(GENERIC_REPLY.get(lang, GENERIC_REPLY["en"]))

    await bot.process_commands(message)


# ── READY ────────────────────────────────────────────
@bot.event
async def on_ready():
    bot.add_view(OpenTicketButton())
    bot.add_view(TicketView())
    bot.add_view(LogView(0, 0))
    print(f"Bot connecté : {bot.user} ({bot.user.id})")
    try:
        synced = await bot.tree.sync()
        print(f"OK {len(synced)} commande(s) sync")
    except Exception as e:
        print(f"ERREUR sync : {e}")


@bot.event
async def on_guild_channel_delete(channel):
    if not (hasattr(channel, "category") and channel.category and TICKET_CATEGORY.lower() in channel.category.name.lower()):
        return
    log_ch = discord.utils.get(channel.guild.text_channels, name=LOG_CHANNEL)
    if not log_ch:
        return
    embed = discord.Embed(title="🗑️ Ticket Deleted", color=0xF23F42)
    embed.add_field(name="Channel", value=f"`#{channel.name}`", inline=True)
    embed.add_field(name="Status",  value="❌ Deleted",          inline=True)
    embed.set_footer(text=f"Channel: {channel.name}")

    class ReopenDeletedView(ui.View):
        def __init__(self): super().__init__(timeout=None)

        @ui.button(label="🔓 Reopen Ticket", style=discord.ButtonStyle.blurple)
        async def reopen_deleted(self, interaction: discord.Interaction, button: ui.Button):
            guild    = interaction.guild
            category = discord.utils.get(guild.categories, name=TICKET_CATEGORY)
            if not category:
                category = await guild.create_category(TICKET_CATEGORY)
            staff_role = discord.utils.get(guild.roles, name=STAFF_ROLE_NAME) or discord.utils.get(guild.roles, name="Admin")
            overwrites = {guild.default_role: discord.PermissionOverwrite(read_messages=False)}
            if staff_role:
                overwrites[staff_role] = discord.PermissionOverwrite(read_messages=True, send_messages=True)
            new_ch = await guild.create_text_channel(channel.name, category=category, overwrites=overwrites)
            welcomed.add(new_ch.id)
            await new_ch.send(f"🔓 Ticket reopened by {interaction.user.mention}!")
            ctrl_embed = discord.Embed(description="Use the buttons below to manage this ticket.", color=0x2B2D31)
            await new_ch.send(embed=ctrl_embed, view=TicketView())
            embed.color = 0x23A55A
            embed.set_field_at(1, name="Status", value=f"🔓 Reopened by {interaction.user.mention}", inline=True)
            await interaction.message.edit(embed=embed, view=None)
            await interaction.response.send_message(f"✅ Ticket reopened: {new_ch.mention}", ephemeral=True)

    await log_ch.send(embed=embed, view=ReopenDeletedView())


bot.run(BOT_TOKEN)
