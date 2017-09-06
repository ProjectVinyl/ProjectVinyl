module ProjectVinyl
  module Bbc
    class Emoticons
      Emoticons = %w[
        ajbemused
        ajsleepy
        ajsmug
        applejackconfused
        applejackunsure
        applecry
        eeyup
        fluttercry
        flutterrage
        fluttershbad
        fluttershyouch
        fluttershysad
        yay
        heart
        pinkiecrazy
        pinkiegasp
        pinkiehappy
        pinkiesad2
        pinkiesmile
        pinkiesick
        coolphoto
        rainbowderp
        rainbowdetermined2
        rainbowhuh
        rainbowkiss
        rainbowlaugh
        rainbowwild
        iwtcird
        raritycry
        raritydespair
        raritystarry
        raritywink
        duck
        unsuresweetie
        scootangel
        twilightangry2
        twilightoops
        twilightblush
        twilightsheepish
        twilightsmile
        facehoof
        moustache
        twistnerd
        twistoo
        trixieshiftleft
        trixieshiftright
        cheericonfused
        cheeriderp
        cheerismile
        derpyderp1
        derpyderp2
        derpytongue2
        trollestia
        redheartgasp
        zecora
      ].freeze
      
      def self.is_defined_emote(emote)
        !all.index(emote).nil?
      end
      
      def self.all
        Emoticons
      end
      
      def self.emoticon_tag(name)
        "<i class=\"emote\" data-emote=\"#{name}\">:#{name}:</i>"
      end
    end
  end
end