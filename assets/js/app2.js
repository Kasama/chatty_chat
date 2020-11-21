const reportError = where => error => console.error(where, error)
const log = console.log

// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

import("helloworld")
  .catch(reportError("importing helloworld"))
  .then(stuff => window.helloworld = stuff)

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
import channel from './socket'

const connectButton = document.getElementById('connect')
const callButton = document.getElementById('call')
const disconnectButton = document.getElementById('disconnect')

const remoteVideo = document.getElementById('remote-stream')
const localVideo = document.getElementById('local-stream')
const remoteStream = new MediaStream()

const setVideoStream = videoElement => stream => {
  videoElement.srcObject = stream
  return stream
}
const setRemoteVideoStream = setVideoStream(remoteVideo)
const setLocalVideoStream = setVideoStream(localVideo)

const unsetVideoStream = (videoElement) => {
  if (videoElement.srcObject)
    videoElement.srcObject.getTracks().forEach(track => track.stop())
  videoElement.removeAttribute('src')
  videoElement.removeAttribute('srcObject')
}

setRemoteVideoStream(remoteStream)

let peerConnection

disconnectButton.disabled = true
callButton.disabled = true
connectButton.onclick = connect
callButton.onclick = call
disconnectButton.onclick = () => disconnect(false)

function connect() {
  connectButton.disabled = true
  disconnectButton.disabled = false
  callButton.disabled = false

  const requiredMedia = {
    audio: true,
    video: true,
  }

  return navigator.mediaDevices
          .getUserMedia(requiredMedia)
          .then(setLocalVideoStream)
          .catch(reportError("getUserMedia"))
          .then(stream => peerConnection = createPeerConnection(stream))
}

function disconnect(isFromRemote) {
  connectButton.disabled = false
  disconnectButton.disabled = true
  callButton.disabled = true
  unsetVideoStream(localVideo)
  unsetVideoStream(remoteVideo)
  setRemoteVideoStream(new MediaStream())
  if (peerConnection) peerConnection.close()
  peerConnection = null
  remoteStream
  if (!isFromRemote) pushPeerMessage('disconnect')({})
}

function createPeerConnection(stream) {
  let peerConnection = new RTCPeerConnection({
    iceServers: [
      {
        urls: 'turn:turn-server.robertoalegro.com:3478?transport=tcp',
        username: 'roberto',
        credential: 'roberto123',
      },
    ],
  })
  const handleOnTrack = event => {
    remoteStream.addTrack(event.track)
  }
  const handleOnIceCandidate = event => {
    if (!!event.candidate) {
      pushPeerMessage('ice-candidate')(event.candidate)
    }
  }
  peerConnection.ontrack = handleOnTrack
  peerConnection.onicecandidate = handleOnIceCandidate
  stream.getTracks().forEach(track => peerConnection.addTrack(track))
  return peerConnection
}

const pushPeerMessage = type => content => {
  channel.push('peer-message', {
    body: JSON.stringify({
      type, content
    })
  })
}

function call() {
  return peerConnection.createOffer()
    .then(offer => {
      peerConnection.setLocalDescription(offer)
      const pushVideoOffer = pushPeerMessage('video-offer')
      pushVideoOffer(offer)
    })
}

function receiveRemote(offer) {
  const remoteDescription = new RTCSessionDescription(offer)
  peerConnection.setRemoteDescription(remoteDescription)
}

function answerCall(offer) {
  receiveRemote(offer)
  peerConnection.createAnswer()
    .then(ans => peerConnection.setLocalDescription(ans))
    .then(() => pushPeerMessage('video-answer')(peerConnection.localDescription))
    .catch(reportError('answerCall'))
}

window.addEventListener('beforeunload', disconnect)

channel.on('peer-message', payload => {
  const message = JSON.parse(payload.body)
  switch (message.type) {
    case 'video-offer':
      log('offered: ', message.content.type)
      answerCall(message.content)
      break
    case 'video-answer':
      log('anwered: ', message.content.type)
      receiveRemote(message.content)
      break
    case 'ice-candidate':
      log('candidate: ', message.content.type)
      const candidate = new RTCIceCandidate(message.content)
      peerConnection.addIceCandidate(candidate).catch(reportError('ice-candidate'))
      break
    case 'disconnect':
      log('disconnecting...')
      disconnect(true)
      break
    default:
      reportError('Unhandled message type')(message.type)
  }
})
