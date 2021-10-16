from string import ascii_uppercase
from collections import OrderedDict
import numpy as np
import cython
import itertools
import pprint

cpdef list alphabet = list(ascii_uppercase)


cpdef int numb(str letter):
    return alphabet.index(letter)


cpdef str alph(int number):
    return alphabet[number]


cdef dict wheels = {
    "ETW":
        {"wiring_string": "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "turnover": []},
    "I":
        {"wiring_string": "EKMFLGDQVZNTOWYHXUSPAIBRCJ", "turnover": [numb("Q")]},
    "II":
        {"wiring_string": "AJDKSIRUXBLHWTMCQGZNPYFVOE", "turnover": [numb("E")]},
    "III":
        {"wiring_string": "BDFHJLCPRTXVZNYEIWGAKMUSQO", "turnover": [numb("V")]},
    "IV":
        {"wiring_string": "ESOVPZJAYQUIRHXLNFTGKDCMWB", "turnover": [numb("J")]},
    "V":
        {"wiring_string": "VZBRGITYUPSDNHLXAWMJQOFECK", "turnover": [numb("Z")]},
    "VI":
        {"wiring_string": "JPGVOUMFYQBENHZRDKASXLICTW", "turnover": [numb("M"), numb("Z")]},
    "VII":
        {"wiring_string": "NZJHGRCXMYSWBOUFAIVLPEKQDT", "turnover": [numb("M"), numb("Z")]},
    "VIII":
        {"wiring_string": "FKQHTLXOCBJSPDZRAMEWNIUYGV", "turnover": [numb("M"), numb("Z")]},
    "UKW-A":
        {"wiring_string": "ZYXWVUTSRQPONMLKJIHGFEDCBA", "turnover": []},
    "UKW-B":
        {"wiring_string": "YRUHQSLDPXNGOKMIEBFZCWVJAT", "turnover": []},
    "UKW-C":
        {"wiring_string": "FVPJIAOYEDRZXWGCTKUQSBNMHL", "turnover": []}
}


def wiring_dict(wiring_str):
    d = dict()
    for i, c in enumerate(list(wiring_str)):
        d[alph(i)] = c

    return dict(sorted(d.items()))


cpdef dict symmetrical_wiring_dict(str wiring_str):
    d = dict()
    for i, c in enumerate(list(wiring_str)):
        if c not in d:
            d[alph(i)] = c
            d[c] = alph(i)
    return d


cpdef str random_wiring_string():
    cdef list remaining_alphabet = alphabet[:]

    d = dict()
    for letter in alphabet:
        if letter not in d:
            connection = remaining_alphabet[np.random.randint(0, len(remaining_alphabet))]
            d[letter] = connection
            d[connection] = letter
            remaining_alphabet.remove(letter)
            if letter != connection:
                remaining_alphabet.remove(connection)

    return ''.join(dict(sorted(d.items())).values())


cpdef str format_wiring_dict(dict d):
    pp = pprint.PrettyPrinter(indent=2)
    return pp.pformat(d)


cpdef validate_wiring(str wiring):
    assert len(wiring) == 26, f"Incorrect wiring length: {wiring}"


cdef class Plugboard:
    cdef public dict wiring

    def __init__(self, list connections):

        cdef str end1
        cdef str end2

        d = dict()
        for end1, end2 in connections:
            assert end1 != end2, f"Cannot plug to itself: {end1}, {end2}"
            d[end1] = end2
            d[end2] = end1

        self.wiring = d

    cpdef str forward_char(self, str c):
        if c in self.wiring:
            return self.wiring[c]
        else:
            return c

cdef class Rotor:

    cdef public:
        str name
        dict wiring
        int rotor_position
        list notch_positions
        int ring_setting
        list forward_mapping
        list backward_mapping

    def __init__(self,
                 str name,
                 dict wiring,
                 int rotor_position,
                 list notch_positions,
                 int ring_setting):

        self.name = name
        self.wiring = wiring
        self.rotor_position = rotor_position
        self.notch_positions = notch_positions
        self.ring_setting = ring_setting

        cdef dict d = {v: k for k, v in self.wiring.items()}
        self.forward_mapping = [numb(i) for i in self.wiring.values()]
        self.backward_mapping = [numb(i) for i in d.keys()]

    @classmethod
    def from_preset(cls, str wheel_name, int rotor_position, int ring_setting):
        assert wheel_name in wheels, f"Unknown wheel: {wheel_name}"

        cdef list notch_positions = wheels[wheel_name]["turnover"]
        cdef str wiring_str = wheels[wheel_name]["wiring_string"]
        d = wiring_dict(wiring_str)

        return cls(wheel_name, d, rotor_position, notch_positions, ring_setting)

    cpdef int encipher_forward(self, int k):
        shift = self.rotor_position - self.ring_setting
        return (self.forward_mapping[(k + shift + 26) % 26] - shift + 26) % 26

    cpdef int encipher_backward(self, int k):
        shift = self.rotor_position - self.ring_setting
        return (self.backward_mapping[(k + shift + 26) % 26] - shift + 26) % 26

    def at_notch(self):
        return self.rotor_position in self.notch_positions

    cpdef turnover(self):
        self.rotor_position = (self.rotor_position + 1) % 26


cdef class RotorTray:

    cdef public:
        Rotor reflector
        Rotor left_rotor
        Rotor middle_rotor
        Rotor right_rotor
        list rotor_tray


    def __init__(self, list rotor_tray):

        self.rotor_tray = rotor_tray
        self.reflector = rotor_tray[0]
        self.left_rotor = rotor_tray[1]
        self.middle_rotor = rotor_tray[2]
        self.right_rotor = rotor_tray[3]

    cpdef rotate(self):

        if self.middle_rotor.at_notch():
            self.middle_rotor.turnover()
            self.left_rotor.turnover()
        elif self.right_rotor.at_notch():
            self.middle_rotor.turnover()

        self.right_rotor.turnover()

    cpdef int forward_pass(self, int k):
        k = self.right_rotor.encipher_forward(k)
        k = self.middle_rotor.encipher_forward(k)
        return self.left_rotor.encipher_forward(k)

    cpdef int backward_pass(self, int k):
        k = self.left_rotor.encipher_backward(k)
        k = self.middle_rotor.encipher_backward(k)
        return self.right_rotor.encipher_backward(k)

    cpdef int reflect(self, int k):
        return self.reflector.encipher_forward(k)


cdef class EnigmaMachine:

    cdef public:
        RotorTray rotor_tray
        Plugboard plugboard

    def __init__(self,
                 RotorTray rotor_tray,
                 Plugboard plugboard):

        self.rotor_tray = rotor_tray
        self.plugboard = plugboard

    @cython.boundscheck(False)  # compiler directive
    @cython.wraparound(False)  # compiler directive
    cpdef str encrypt(self, str message):
        the_list = [self.encode(x) for x in list(message)]
        return "".join(the_list)

    cpdef str encode(self, str c):
        self.rotor_tray.rotate()

        k = numb(self.plugboard.forward_char(c))
        k = self.rotor_tray.forward_pass(k)
        k = self.rotor_tray.reflect(k)
        k = self.rotor_tray.backward_pass(k)
        c_out = self.plugboard.forward_char(alph(k))

        return c_out


cpdef float compute_ioc(str text):

    c = len(alphabet)
    n = len(text)
    numerator = 0.0
    for letter in alphabet:
        count = text.count(letter)
        numerator += count * (count - 1)
    denominator = (n * (n - 1) / c)

    return numerator / denominator
