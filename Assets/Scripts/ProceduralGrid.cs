using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent (typeof (MeshFilter), typeof (MeshRenderer))]
public class ProceduralGrid : MonoBehaviour {

    void Awake () {
        Generate ();
    }

    void OnValidate () {
        Generate ();
    }

    public Color verticeColor = Color.white;
    public int xSegment = 1;
    public int ySegment = 1;
    public Vector2 size = Vector2.one;

    Mesh m_mesh;

    public void Generate () {
        if (xSegment <= 0 || ySegment == 0) {
            throw new System.InvalidOperationException ("xSegment and ySegment must be positive int");
        }

        m_mesh = new Mesh ();
        m_mesh.name = "Procedural Grid";

        int verticeCount = (xSegment + 1) * (ySegment + 1);
        Vector3[] vertices = new Vector3[verticeCount];
        Vector2[] uv = new Vector2[verticeCount];
        Color[] colors = new Color[verticeCount];
        int[] triangles = new int[xSegment * ySegment * 6];

        for (int vIdx = 0, y = 0; y <= ySegment; y++) {
            for (int x = 0; x <= xSegment; x++, vIdx++) {
                vertices[vIdx] = new Vector3 (size.x * ((float) x / xSegment - 0.5f), size.y * ((float) y / ySegment - 0.5f));
                uv[vIdx] = new Vector2 ((float) x / xSegment, (float) y / ySegment);
                colors[vIdx] = verticeColor;
            }
        }

        for (int vIdx = 0, tIdx = 0, y = 0; y < ySegment; y++, vIdx++) {
            for (int x = 0; x < xSegment; x++, vIdx++, tIdx += 6) {
                triangles[tIdx] = vIdx;
                triangles[tIdx + 1] = triangles[tIdx + 4] = vIdx + xSegment + 1;
                triangles[tIdx + 2] = triangles[tIdx + 3] = vIdx + 1;
                triangles[tIdx + 5] = vIdx + xSegment + 2;
            }
        }

        m_mesh.vertices = vertices;
        m_mesh.uv = uv;
        m_mesh.triangles = triangles;
        m_mesh.colors = colors;
        m_mesh.RecalculateNormals ();
        m_mesh.RecalculateTangents ();
        m_mesh.RecalculateBounds ();

        this.GetComponent<MeshFilter> ().mesh = m_mesh;
        var meshCollider = this.GetComponent<MeshCollider> ();
        if (meshCollider != null) {
            meshCollider.sharedMesh = m_mesh;
        }
    }
}