# 📚 BiblioQuest

**BiblioQuest** é um jogo de quebra-cabeça (Puzzle) Top-Down 2D desenvolvido na Godot Engine. O jogador assume o papel de um arquivista noturno em uma grande biblioteca universitária, precisando resolver enigmas de lógica espacial e ótica para destrancar os acervos após uma falha no sistema de segurança.

Este projeto foi desenvolvido como requisito para a disciplina de **Computação Gráfica e Realidade Virtual (2026.1)**, ministrada pela Profª Andréia Formico, no curso de Ciência da Computação da **Universidade de Fortaleza (UNIFOR)**.

---

## 🎮 O Jogo

Um pico de energia corrompeu o sistema de segurança eletrônico do acervo, trancando setores inteiros e ativando o protocolo de quarentena. Para destrancar as portas, você precisa usar o sistema de backup analógico: redirecionar feixes de luz por meio de prismas e espelhos antigos até os receptores de cada porta.

### ⚙️ Mecânicas Principais (Foco em Computação Gráfica)
O desenvolvimento do jogo teve como foco a aplicação prática de conceitos matemáticos e físicos da Computação Gráfica:

**Vetores** e **Interpolação Linear (Lerp)** para garantir uma translação visualmente suave e matematicamente precisa entre as coordenadas da grade.
* **Física de Luz e Reflexão:** A mecânica central de puzzle envolve ótica. Utilizamos emissão de feixes contínuos (`RayCast2D`) e cálculos vetoriais em tempo real. Quando a luz atinge um espelho rotacionado, o motor calcula o **Vetor Normal** da superfície para determinar o **Ângulo de Reflexão** perfeito, desenhando a trajetória da luz de forma dinâmica.
* **Feedback Visual:** Uso de transformações geométricas contínuas, como funções de **Escala** aplicadas aos receptores das portas para simular pulsação luminosa (feedback visual) quando o enigma é resolvido.

---

## 💻 Tecnologias e Ferramentas

* **Motor Gráfico:** [Godot Engine 4.2.1](https://godotengine.org/)
* **Linguagem:** GDScript
* **Arte:** Pixel Art customizada e bancos de *assets* gratuitos focados em visão Top-Down 2D.

---

## ⌨️ Controles

* `W`, `A`, `S`, `D` ou `Setas`: Movimenta o Arquivista (e empurra estantes).
* `Espaço` / `E` / `Q`: Interage com os espelhos (rotaciona os espelhos gradativamente).
* `R`: Reinicia a sala (caso uma estante fique presa).

---

## 🚀 Como executar o projeto

1. Faça o clone deste repositório:
   ```bash
   git clone [https://github.com/davidkleinn/BiblioQuest.git]