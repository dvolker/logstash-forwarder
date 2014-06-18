package schema

import (
	"fmt"
	"lsf/panics"
	"lsf/system"
	"net/url"
)

type PortId string
type portType int

const (
	localPort  portType = 0
	remotePort          = 1
)

const AnonPortId PortId = ""

// ----------------------------------------------------------------------
// Port
// ----------------------------------------------------------------------

// lsf.RemotePort describes a remote LSF port.
type Port struct {
	local   bool
	Id      PortId // TODO REVU first ..
	Address *url.URL
	// todo certs ..
}

func (p Port) Path() string { return p.Address.Path }

// recorded elements of LogStream object
var portElem = struct {
	is_local, id, address string
}{
	is_local: "local",
	id:       "id",
	address:  "address",
}

// REVU: TODO sort mappings at sysrec..
func (t *Port) Mappings() map[string][]byte {
	m := make(map[string][]byte)
	m[portElem.id] = []byte(t.Id)
	m[portElem.address] = []byte(t.Address.String())
	return m
}

func (t *Port) String() string {
	var locality = "local"
	if !t.local {
		locality = "remote"
	}
	return fmt.Sprintf("port %s %s %s", t.Id, locality, t.Path())
}

func PortDigest(doc system.Document) string {
	port := DecodePort(doc)
	return port.String()
}

func DecodePort(data system.DataMap) *Port {
	m := data.Mappings()
	addr, e := url.Parse(string(m[portElem.address]))
	panics.OnError(e, "BUG", "schema.DecodePort")
	return &Port{
		Id:      PortId(string(m[portElem.id])),
		Address: addr,
	}
}

// returns nil, nil on "" path input
// REVU: needs ID
func NewLocalPort(path string) (*Port, error) {
	if path == "" {
		return nil, nil
	}

	address, e := url.Parse(path)
	if e != nil {
		return nil, e
	}

	port := &Port{
		local:   true,
		Address: address,
	}
	return port, nil
}

func NewRemotePort(id, host string, portno int) (*Port, error) {

	path := fmt.Sprintf("%s:%d", host, portno)
	address, e := url.Parse(path)
	if e != nil {
		return nil, e
	}
	port := &Port{
		local:   false,
		Id:      PortId(id),
		Address: address,
	}
	return port, nil
}
