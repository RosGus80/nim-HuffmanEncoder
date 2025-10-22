import std/algorithm
import tables

type 
    EncodedSymbol = object
        ##[ Хранит все данные об абстракции символа - сам символ, его вероятность появления в тексте, а так же 
        код, которым мы его кодируем (он ищначально равен "", и эта стркоа дописывается в процессе извлечения 
        данных о кодируемом сообщении) ]##

        symbol: char
        probability: float
        code: string

    Node = object
        ##[ Абстракция "узла" символов - алгоритм Хаффмана объединяет символы в "группы" и присваивает им кодировку (0 или 1), пока 
        групп не станет 1. У группы есть параметр "общей вероятности" появления в тексте - сначала присваиваются и сливаются с 
        другими самые невероятные - чтобы они участвовали в наибольшем кол-ве итераций получения символа в значении (так самые 
        вероятные символы получат наименьшую длину кода) ]##

        symbols: seq[EncodedSymbol]
        total_prob: float
    
    HuffmanEncoder* = object
        ## Ключевой класс кодировки - объединяет всю соответствующую логику
        
        input_text: string
        input_dict: Table[char, float]

        #[ encoding_dict - "зеркало" decoding_dict (все ключи encoding_dict - все значния decoding_dict и наоборот). Можно обойтись и 
        без этого, но в целом декодировать легче не по значениям encoding_dict, а по ключам decoding_dict ]#
        encoding_dict: Table[char, string]

        total_bytes: int


proc add_symbol(node: var Node, new_symbol: EncodedSymbol) =
    node.symbols.add(new_symbol)
    node.total_prob += new_symbol.probability

proc compare_nodes(a, b: Node): int =
    cmp(a.total_prob, b.total_prob)

proc symbol_in_sequence(sequence: seq[EncodedSymbol], symbol: char): bool = 
    var is_true: bool = false

    for item in sequence:

        if item.symbol == symbol:
            is_true = true
            break

    is_true

proc huffman_count_total_bytes(huff: HuffmanEncoder): int = 
    var output: int = 0

    for it in huff.encoding_dict.values:
        output += it.len

    output

proc huffman_count_dict(input_str: string): Table[char, float] =
    ##[ Читает каждый символ и определяет его частоту появления в тексте. Потом считает соответственно его вероятность 
        появления в тексте и возвращает словарь [символ]: вероятность ]##

    var out_dict: Table[char, float]

    for c in input_str:
        if not out_dict.hasKey(c):
            var counter: int = 0

            for cc in input_str:
                if c == cc: counter += 1
            
            let prob: float = float(counter) / float(input_str.len)
            out_dict[c] = prob
    
    out_dict

proc huffman_encode_dict(huff: HuffmanEncoder): Table[char, string] =
    ##[ Ключевой алгоритм кодировки. Из полученного сообщения находит вероятности для каждого символа, распределяет каждый 
        символ по группам (каждому символу - одна группа). Далее объединяет каждые две самые невероятные группы, добавляя 
        каждому символу из одной из изначальных групп "0" в коде, а из другой - "1" и перенося все символы в новую 
        "объединенную" группу. Так продолжается, пока групп не останется 1. Потом возвращает encoding_dit и decoding_dict 
        (зеркальные - см. определение HuffmanEncoder) ]##

    var symbols_seq: seq[EncodedSymbol]
    var nodes_seq: seq[Node]

    for it in huff.input_dict.pairs:

        if not symbol_in_sequence(symbols_seq, it[0]):
            var new_symb = EncodedSymbol(
                symbol: it[0], 
                probability: it[1], 
                code: ""
            )
            symbols_seq.add(new_symb)

    for symbol in symbols_seq:
        var new_node = Node()
        new_node.add_symbol(symbol)
        nodes_seq.add(new_node)

    while nodes_seq.len > 1:
        nodes_seq.sort(compare_nodes)

        var last_node: Node = nodes_seq[0]
        nodes_seq.del(0)

        for i in 0..<last_node.symbols.len:
            last_node.symbols[i].code = "0" & last_node.symbols[i].code
        
        nodes_seq.sort(compare_nodes)

        var second_last_node: Node = nodes_seq[0]
        nodes_seq.del(0)

        for i in 0..<second_last_node.symbols.len:
            second_last_node.symbols[i].code = "1" & second_last_node.symbols[i].code

        var new_node = Node()

        for symb in last_node.symbols:
            new_node.add_symbol(symb)
        for symb in second_last_node.symbols:
            new_node.add_symbol(symb)

        nodes_seq.add(new_node)

    let last_node: Node = nodes_seq[0]

    var output_encoding_dict: Table[char, string]

    for s in last_node.symbols:
        output_encoding_dict[s.symbol] = s.code
    
    output_encoding_dict

proc encode_message*(huff: HuffmanEncoder): string = 
    var output: string = ""

    for ch in huff.input_text:
        output = output & huff.encoding_dict[ch]

    output

proc decode_message*(huff: HuffmanEncoder, encoded_message: string): string = 
    var decoding_dict: Table[string, char]
    for k, v in huff.encoding_dict.pairs:
        decoding_dict[v] = k

    var output_string: string
    var current_code: string

    for ch in encoded_message:
        current_code = current_code & ch

        if decoding_dict.has_key(current_code):
            output_string = output_string & decoding_dict[current_code]
            current_code = ""

    output_string

proc new_huffman_encoder*(input_string: string): HuffmanEncoder = 
    var new_huffman = HuffmanEncoder(
        input_text: input_string,
        input_dict: huffman_count_dict(input_string),
    )

    new_huffman.encoding_dict = huffman_encode_dict(new_huffman)

    new_huffman.total_bytes = huffman_count_total_bytes(new_huffman)

    new_huffman
