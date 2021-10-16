from enigma import EnigmaMachine, Rotor, RotorTray, Plugboard
from string import ascii_uppercase
import itertools
import numpy as np
import pprint


alphabet = list(ascii_uppercase)
c = len(alphabet)


def compute_ioc(text: str) -> float:

    n = len(text)
    numerator = 0.0
    for letter in alphabet:
        count = text.count(letter)
        numerator += count * (count - 1)
    denominator = (n * (n - 1) / c)

    return numerator / denominator


def main():
    inp = "OZLUDYAKMGMXVFVARPMJIKVWPMBVWMOIDHYPLAYUWGBZFAFAFUQFZQISLEZMYPVBRDDLAGIHIFUJDFADORQOOMIZPYXDCBPWDSSNUSYZT" \
          "JEWZPWFBWBMIEQXRFASZLOPPZRJKJSPPSTXKPUWYSKNMZZLHJDXJMMMDFODIHUBVCXMNICNYQBNQODFQLOGPZYXRJMTLMRKQAUQJPADHD" \
          "ZPFIKTQBFXAYMVSZPKXIQLOQCVRPKOBZSXIUBAAJBRSNAFDMLLBVSYXISFXQZKQJRIQHOSHVYJXIFUZRMXWJVWHCCYHCXYGRKMKBPWRDB" \
          "XXRGABQBZRJDVHFPJZUSEBHWAEOGEUQFZEEBDCWNDHIAQDMHKPRVYHQGRDYQIOEOLUBGBSNXWPZCHLDZQBWBEWOCQDBAFGUVHNGCIKXEI" \
          "ZGIZHPJFCTMNNNAUXEVWTWACHOLOLSLTMDRZJZEVKKSSGUUTHVXXODSKTFGRUEIIXVWQYUIPIDBFPGLBYXZTCOQBCAHJYNSGDYLREYBRA" \
          "KXGKQKWJEKWGAPTHGOMXJDSQKYHMFGOLXBSKVLGNZOAXGVTGXUIVFTGKPJU"

    inp_short = inp[:300]

    exp = "IPROPOSETOCONSIDERTHEQUESTIONCANMACHINESTHINKTHISSHOULDBEGINWITHDEFINITIONSOFTHEMEANINGOFTHETERMSMACHINEA" \
          "NDTHINKTHEDEFINITIONSMIGHTBEFRAMEDSOASTOREFLECTSOFARASPOSSIBLETHENORMALUSEOFTHEWORDSBUTTHISATTITUDEISDANG" \
          "EROUSIFTHEMEANINGOFTHEWORDSMACHINEANDTHINKARETOBEFOUNDBYEXAMININGHOWTHEYARECOMMONLYUSEDITISDIFFICULTTOESC" \
          "APETHECONCLUSIONTHATTHEMEANINGANDTHEANSWERTOTHEQUESTIONCANMACHINESTHINKISTOBESOUGHTINASTATISTICALSURVEYSU" \
          "CHASAGALLUPPOLLBUTTHISISABSURDINSTEADOFATTEMPTINGSUCHADEFINITIONISHALLREPLACETHEQUESTIONBYANOTHERWHICHISC" \
          "LOSELYRELATEDTOITANDISEXPRESSEDINRELATIVELYUNAMBIGUOUSWORDS"

    # print(compute_ioc(inp))
    # print(compute_ioc(exp))

    expected_english_ioc = 1.73
    expected_german_ioc = 2.05

    # Find rotors
    available_rotors = ["I", "II", "III", "IV", "V"]
    pb = Plugboard([])

    ioc_scores = []
    combinations = []
    ring_positions = []

    rotor_permutations = list(itertools.permutations(available_rotors, 3))
    # rotor_permutations = [("II", "V", "III")]
    explore_range = c

    for rotors in rotor_permutations:
        print(f"Combination: rotors = {rotors}")

        top_ioc = - np.inf
        top_positions = ()
        for rp1, rp2, rp3 in list(itertools.product(range(explore_range), repeat=3)):
            rt = RotorTray([
                Rotor.from_preset("UKW-B", 0, 0),
                Rotor.from_preset(rotors[0], rp1, 0),
                Rotor.from_preset(rotors[1], rp2, 0),
                Rotor.from_preset(rotors[2], rp3, 0)
            ])
            e = EnigmaMachine(rt, pb)
            decoded_text = e.encrypt(inp_short)
            ioc = compute_ioc(decoded_text)

            if ioc > top_ioc:
                top_ioc = ioc
                top_positions = (rp1, rp2, rp3)

        ioc_scores.append(top_ioc)
        combinations.append(rotors)
        ring_positions.append(top_positions)

    # Expected answer: II, V, III
    # Rotor positions: 7, 4, 19
    pp = pprint.PrettyPrinter(indent=2)
    print(pp.pformat(sorted(zip(ioc_scores, combinations, ring_positions))))


if __name__ == '__main__':
    main()
