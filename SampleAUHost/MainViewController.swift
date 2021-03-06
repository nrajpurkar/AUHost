//
//  MainViewController.swift
//  AUHost
//
//  Created by Vlad Gorlov on 21.06.15.
//  Copyright © 2015 WaveLabs. All rights reserved.
//

import AVFoundation
import Cocoa
import CoreAudioKit
import MediaLibrary

// Links: [Developer Forums: MLMediaLibrary in Mavericks not working?](https://devforums.apple.com/message/1125821#1125821)
class MainViewController: NSViewController {

   private lazy var buttonPlay = NSButton()
   private lazy var mediaItemView = MediaItemView()
   private lazy var tableColumn1 = NSTableColumn()
   private lazy var tableEffects = NSTableView()
   private lazy var clipView1 = NSClipView()
   private lazy var scrollView1 = NSScrollView()
   private lazy var buttonOpenEffectView = NSButton()
   private lazy var tableColumn2 = NSTableColumn()
   private lazy var tablePresets = NSTableView()
   private lazy var clipView2 = NSClipView()
   private lazy var scrollView2 = NSScrollView()
   private lazy var stackView2 = NSStackView()
   private lazy var stackView1 = NSStackView()

   let viewModel = MainViewUIModel()

   override func loadView() {
      view = NSView()
   }

   init() {
      super.init(nibName: nil, bundle: nil)
      setupUI()
      setupLayout()
      setupHandlers()
      tableEffects.delegate = self
      tableEffects.dataSource = self

      tablePresets.delegate = self
      tablePresets.dataSource = self
   }

   override func viewDidAppear() {
      super.viewDidAppear()
      viewModel.reloadEffects()
   }

   required init?(coder: NSCoder) {
      fatalError("Please use this class from code.")
   }
}

extension MainViewController: NSTableViewDataSource {

   func numberOfRows(in tableView: NSTableView) -> Int {
      switch tableView {
      case tableEffects:
         return viewModel.availableEffects.count + 1
      case tablePresets:
         return viewModel.availablePresets.count + 1
      default:
         fatalError("Unknown tableView: \(tableView)")
      }
   }

   func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
      let label = NSTextField()
      label.isBezeled = false
      label.isEditable = false
      label.drawsBackground = false
      switch tableView {
      case tableEffects:
         if row == 0 {
            label.stringValue = "- No Effect -"
         } else {
            let component = viewModel.availableEffects[row - 1]
            label.stringValue = component.name
         }
         return label
      case tablePresets:
         if row == 0 {
            label.stringValue = "- Default Preset -"
         } else {
            let preset = viewModel.availablePresets[row - 1]
            label.stringValue = preset.name
         }
         return label
      default:
         fatalError("Unknown tableView: \(tableView)")
      }
   }
}

extension MainViewController: NSTableViewDelegate {

   func tableViewSelectionDidChange(_ aNotification: Notification) {
      guard let tableView = aNotification.object as? NSTableView, tableView.selectedRow >= 0 else {
         return
      }

      switch tableView {
      case tableEffects:
         viewModel.closeEffectView()
         if tableView.selectedRow == 0 {
            log.debug(.controller, "Clearing effect")
            viewModel.selectEffect(nil, completion: nil)
         } else {
            let row = tableView.selectedRow - 1
            if row < viewModel.availableEffects.count {
               let component = viewModel.availableEffects[row]
               log.debug(.controller, "Selecting effect: \"\(component.name)\"")
               viewModel.selectEffect(component) { [weak self] _ in
                  DispatchQueue.main.async {
                     self?.actionToggleEffectView()
                  }
               }
            }
         }
      case tablePresets:
         if tableView.selectedRow == 0 {
            log.debug(.controller, "Clearing preset")
            viewModel.selectPreset(nil)
         } else {
            let row = tableView.selectedRow - 1
            if row < viewModel.availablePresets.count {
               let preset = viewModel.availablePresets[row]
               log.debug(.controller, "Selecting preset: \"\(preset.name)\"")
               viewModel.selectPreset(preset)
            }
         }
      default:
         fatalError("Unknown tableView: \(tableView)")
      }
   }
}

extension MainViewController {

   private func setupHandlers() {
      mediaItemView.onCompleteDragWithObjects = { [weak self] in
         self?.viewModel.handlePastboard($0)
      }
      viewModel.eventHandler = { [weak self] in
         self?.handleEvent($0)
      }
      buttonPlay.target = self
      buttonPlay.action = #selector(actionTogglePlayAudio)

      buttonOpenEffectView.target = self
      buttonOpenEffectView.action = #selector(actionToggleEffectView)
   }

   @objc private func actionTogglePlayAudio() {
      viewModel.togglePlay()
   }

   @objc private func actionToggleEffectView() {
      if viewModel.canOpenEffectView == true {
         viewModel.openEffectView { [weak self] in
            let wc = EffectWindowController()
            wc.contentViewController = $0
            wc.eventHandler = {
               switch $0 {
               case .windowWillClose:
                  self?.viewModel.effectWindowWillClose()
               }
            }
            wc.showWindow(nil)
            self?.viewModel.effectWindowWillOpen(wc)
         }
      }
   }

   private func handleEvent(_ event: MainViewUIModel.Event) {
      switch event {
      case .effectWindowWillOpen:
         buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
      case .effectWindowWillClose:
         buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
      case .loadingEffects(let isBusy):
         if !isBusy {
            tableEffects.reloadData()
         }
         tableEffects.isEnabled = !isBusy
         buttonOpenEffectView.isEnabled = !isBusy && viewModel.canOpenEffectView
      case .willSelectEffect:
         tablePresets.isEnabled = false
      case .didSelectEffect:
         tablePresets.reloadData()
         tablePresets.isEnabled = viewModel.availablePresets.count > 0
         buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
      case .didClearEffect:
         tablePresets.reloadData()
         tablePresets.isEnabled = viewModel.availablePresets.count > 0
         buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
      case .playbackEngineStageChanged(let state):
         switch state {
         case .playing:
            buttonPlay.isEnabled = true
            buttonPlay.title = "Pause"
            buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
         case .stopped:
            buttonPlay.isEnabled = true
            buttonPlay.title = "Play"
            buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
         case .paused:
            buttonPlay.isEnabled = true
            buttonPlay.title = "Resume"
            buttonOpenEffectView.isEnabled = viewModel.canOpenEffectView
         case .updatingGraph:
            buttonPlay.isEnabled = false
            buttonOpenEffectView.isEnabled = false
         }
      case .audioComponentsChanged:
         tablePresets.reloadData()
      case .selectMedia(let url):
         mediaItemView.mediaFileURL = url
      }
   }
}

extension MainViewController {

   private func setupUI() {

      view.addSubview(stackView1)

      stackView1.addArrangedSubview(buttonPlay)
      stackView1.addArrangedSubview(mediaItemView)
      stackView1.addArrangedSubview(stackView2)

      stackView1.alignment = .centerX
      stackView1.distribution = .fill
      stackView1.edgeInsets = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
      stackView1.orientation = .vertical
      stackView1.setHuggingPriority(NSLayoutConstraint.Priority(rawValue: 249.99998474121094), for: .horizontal)
      stackView1.setHuggingPriority(NSLayoutConstraint.Priority(rawValue: 249.99998474121094), for: .vertical)
      stackView1.translatesAutoresizingMaskIntoConstraints = false

      stackView2.addArrangedSubview(scrollView1)
      stackView2.addArrangedSubview(buttonOpenEffectView)
      stackView2.addArrangedSubview(scrollView2)

      stackView2.alignment = .top
      stackView2.distribution = .fillEqually
      stackView2.setHuggingPriority(NSLayoutConstraint.Priority(rawValue: 249.99998474121094), for: .horizontal)
      stackView2.setHuggingPriority(NSLayoutConstraint.Priority(rawValue: 249.99998474121094), for: .vertical)
      stackView2.translatesAutoresizingMaskIntoConstraints = false

      scrollView2.autohidesScrollers = true
      scrollView2.horizontalLineScroll = 19
      scrollView2.horizontalPageScroll = 10
      scrollView2.translatesAutoresizingMaskIntoConstraints = false
      scrollView2.usesPredominantAxisScrolling = false
      scrollView2.verticalLineScroll = 19
      scrollView2.verticalPageScroll = 10

      clipView2.documentView = tablePresets
      clipView2.autoresizingMask = [.width, .height]

      tablePresets.addTableColumn(tableColumn2)

      tablePresets.allowsExpansionToolTips = true
      tablePresets.allowsMultipleSelection = false
      tablePresets.autosaveTableColumns = false
      tablePresets.backgroundColor = .controlBackgroundColor
      tablePresets.gridColor = .gridColor
      tablePresets.intercellSpacing = CGSize(width: 3, height: 2)
      tablePresets.isEnabled = false
      tablePresets.setContentHuggingPriority(.defaultHigh, for: .vertical)
      tablePresets.usesAlternatingRowBackgroundColors = true

      tableColumn2.title = "Presets"
      tableColumn2.isEditable = false

      scrollView2.contentView = clipView2

      buttonOpenEffectView.alignment = .center
      buttonOpenEffectView.bezelStyle = .rounded
      buttonOpenEffectView.font = NSFont.systemFont(ofSize: 13)
      buttonOpenEffectView.imageScaling = .scaleProportionallyDown
      buttonOpenEffectView.setContentHuggingPriority(.defaultHigh, for: .vertical)
      buttonOpenEffectView.title = "e"
      buttonOpenEffectView.translatesAutoresizingMaskIntoConstraints = false

      buttonOpenEffectView.cell?.isBordered = true
      buttonOpenEffectView.cell?.isEnabled = false

      scrollView1.autohidesScrollers = true
      scrollView1.horizontalLineScroll = 19
      scrollView1.horizontalPageScroll = 10
      scrollView1.translatesAutoresizingMaskIntoConstraints = false
      scrollView1.usesPredominantAxisScrolling = false
      scrollView1.verticalLineScroll = 19
      scrollView1.verticalPageScroll = 10

      clipView1.documentView = tableEffects

      clipView1.autoresizingMask = [.width, .height]

      tableEffects.addTableColumn(tableColumn1)

      tableEffects.allowsExpansionToolTips = true
      tableEffects.allowsMultipleSelection = false
      tableEffects.autosaveTableColumns = false
      tableEffects.backgroundColor = .controlBackgroundColor
      tableEffects.gridColor = .gridColor
      tableEffects.intercellSpacing = CGSize(width: 3, height: 2)
      tableEffects.setContentHuggingPriority(.defaultHigh, for: .vertical)
      tableEffects.usesAlternatingRowBackgroundColors = true

      tableColumn1.title = "Effects"
      tableColumn1.isEditable = false

      scrollView1.contentView = clipView1

      mediaItemView.translatesAutoresizingMaskIntoConstraints = false

      buttonPlay.alignment = .center
      buttonPlay.bezelStyle = .rounded
      buttonPlay.font = NSFont.systemFont(ofSize: 13)
      buttonPlay.imageScaling = .scaleProportionallyDown
      buttonPlay.setContentHuggingPriority(.defaultHigh, for: .vertical)
      buttonPlay.title = "Pause"
      buttonPlay.translatesAutoresizingMaskIntoConstraints = false
      buttonPlay.cell?.isBordered = true
      buttonPlay.isEnabled = false
   }

   private func setupLayout() {

      var constraints: [NSLayoutConstraint] = []

      constraints += [
         stackView1.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         stackView1.topAnchor.constraint(equalTo: view.topAnchor),
         view.bottomAnchor.constraint(equalTo: stackView1.bottomAnchor),
         view.trailingAnchor.constraint(equalTo: stackView1.trailingAnchor)
      ]

      constraints += [
         mediaItemView.leadingAnchor.constraint(equalTo: stackView1.leadingAnchor, constant: 8),
         stackView1.trailingAnchor.constraint(equalTo: mediaItemView.trailingAnchor, constant: 8),
         stackView1.trailingAnchor.constraint(equalTo: stackView2.trailingAnchor, constant: 8),
         stackView2.leadingAnchor.constraint(equalTo: stackView1.leadingAnchor, constant: 8)
      ]

      constraints += [
         scrollView1.topAnchor.constraint(equalTo: stackView2.topAnchor),
         scrollView2.topAnchor.constraint(equalTo: stackView2.topAnchor),
         stackView2.bottomAnchor.constraint(equalTo: scrollView1.bottomAnchor),
         stackView2.bottomAnchor.constraint(equalTo: scrollView2.bottomAnchor),
         stackView2.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
         stackView2.widthAnchor.constraint(greaterThanOrEqualToConstant: 320)
      ]

      constraints += [
         buttonOpenEffectView.widthAnchor.constraint(equalToConstant: 36),
         mediaItemView.heightAnchor.constraint(equalToConstant: 98)
      ]

      NSLayoutConstraint.activate(constraints)
   }
}
