# 🧚 Vila Lypia (beta)

Jogo narrativo e educativo feito na **Godot Engine 4.4** com o plugin **Dialogic 2**.
Ele foi pensado para crianças, inclusive crianças autistas ou com sensibilidade sensorial.

A fada **Bella** e o jogador percorrem a vila, conversam com os moradores e reúnem os ingredientes e presentes de uma festa surpresa para a prefeita **Anne**. No caminho há minigames curtos, escolhas de diálogo e amizades a conquistar.

---

## 🎮 Sobre o jogo

- **Gênero:** aventura narrativa / visual novel com minigames
- **Público:** infantil
- **Idioma:** português (com vozes)
- **Plataforma:** PC (Windows)

### Personagens
| Personagem | Papel |
|---|---|
| **Bella** | Fada que acompanha o jogador e dá dicas |
| **Anne** | A prefeita da vila, homenageada da festa |
| **Enzo** | Morador (ovos e velas) |
| **Linna** | Dona da loja (açúcar, fitas, lã) |
| **Pietro** | Morador (chocolate e pincéis) |
| **Profª Hera** | Professora (marcadores e gavetas) |
| **Vincent** | Morador (geleia) |
| **Xerife** | Xerife da vila (fermento e distintivos) |

### Estrutura
1. **Tutorial**: apresenta a Bella e os controles
2. **Primeiros capítulos**: convites e coleta dos ingredientes do bolo
3. **Capítulo 4**: a loja e os presentes para Anne
4. **Capítulo Final**: a festa surpresa na praça

O jogo tem **três finais**, que mudam conforme as amizades e o desempenho nos minigames:
- **Final 1**: O Aniversário Esquecido
- **Final 2**: Um Sorriso Incompleto
- **Final Verdadeiro**: O Coração da Vila *(com o item lendário **Lápis Mágico**)*

### Minigames
Objetos escondidos, coleta de ingredientes pela vila (farinha, ovos, açúcar, chocolate, fermento, geleia), velas, pincéis na floresta, cartão gigante e a montagem do bolo.

---

## ♿ Acessibilidade

O menu **Configurações** foi feito para crianças com sensibilidade sensorial:

- **Sons**: volume separado de Música, Vozes e Efeitos, além da opção *Sons suaves*, que segura barulhos altos de repente
- **Tela**: controle de brilho, *Cores suaves* e *Sem clarões* (desliga os flashes brancos)
- **Texto**: velocidade (Devagar, Normal, Rápida ou Tudo de uma vez), letras maiores e *Avançar sozinho*
- Botão **"Voltar ao normal"** e tudo salvo automaticamente

---

## 🛠️ Como abrir o projeto

1. Instale a **Godot 4.4** (versão padrão, não a .NET):
   https://godotengine.org/download/archive/4.4-stable/
2. Clone o repositório:
   ```bash
   git clone https://github.com/FontesSabrina/Vila-Lypia.git
   ```
3. Na Godot, clique em **Importar** e escolha o arquivo `project.godot`
4. Na primeira abertura a Godot importa todas as imagens e sons, o que leva alguns minutos
5. Aperte **F5** para jogar

> ⚠️ **Use a Godot 4.4.** O Dialogic incluído (2.0-Alpha-19) exige a 4.4 ou mais nova.
> Não abra o projeto na 4.3, porque isso quebra arquivos.

---

## 📁 Estrutura de pastas

```
Vila-Lypia/
├── addons/dialogic/        Plugin de diálogos (Dialogic 2.0-Alpha-19)
├── assets/
│   ├── backgrounds/        Cenários
│   ├── characters/         Retratos dos personagens
│   ├── som/                Músicas, vozes e efeitos
│   ├── fonte/              Fontes
│   └── resources/          Recursos (.tres)
├── scenes/                 Cenas do jogo (.tscn)
│   └── dtl_Dialogic/       Linhas do tempo dos diálogos (.dtl)
├── scripts/                Scripts GDScript (.gd)
└── project.godot
```

### Autoloads
| Nome | Arquivo | Função |
|---|---|---|
| `GameState` | `scripts/GameState.gd` | Progresso, moedas, amizades e final alcançado |
| `Salvamento` | `scripts/Salvamento.gd` | Salvar e carregar o jogo |
| `Dialogic` | `addons/dialogic/...` | Sistema de diálogos |
| `Acessibilidade` | `scripts/Acessibilidade.gd` | Configurações de acessibilidade |

---

## 👩‍💻 Créditos

**Desenvolvimento**
Alexandre do Amaral Quintão
Sabrina Caetano Fontes

**Orientador**
Prof. Paulo Vinicius Moreira Dutra

**Projeto de Extensão**
Instituto Federal do Sudeste de Minas Gerais (IF Sudeste MG)

**Ferramentas**
- [Godot Engine](https://godotengine.org/)
- [Dialogic](https://github.com/dialogic-godot/dialogic)
- Fish Audio (vozes)
- Google Flow / Whisk (imagens)
- Photoroom (remoção de fundo)

---

*Obrigada por jogar!* 💛
